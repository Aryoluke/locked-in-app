import 'package:flutter/foundation.dart';

import '../models/workout.dart';
import '../models/xp.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../services/xp_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;
  final ApiService _api = ApiService.instance;
  final SyncService _sync = SyncService.instance;
  final XpService _xp = XpService.instance;

  List<Workout> _workouts = [];
  Workout? _activeWorkout;
  List<WorkoutSet> _activeSets = [];
  List<WorkoutTemplate> _templates = [];
  List<Exercise> _library = [];
  List<PersonalRecord> _prs = [];
  bool _loading = false;

  List<Workout> get workouts => List.unmodifiable(_workouts);
  Workout? get activeWorkout => _activeWorkout;
  List<WorkoutSet> get activeSets => List.unmodifiable(_activeSets);
  List<WorkoutTemplate> get templates => List.unmodifiable(_templates);
  List<Exercise> get library => List.unmodifiable(_library);

  Future<void> init() async {
    await _loadWorkouts();
    await _loadTemplates();
    await _loadLibrary();
    await _loadPRs();
    await _resumeActiveWorkout();
  }

  Future<void> _loadWorkouts() async {
    try {
      final rows = await _db.loadWorkouts(limit: 100);
      _workouts = rows.map((r) => Workout.fromMap(r)).toList();
    } catch (_) {}
  }

  Future<void> _loadTemplates() async {
    try {
      final rows = await _db.queryAll('templates', orderBy: 'updated_at DESC');
      _templates =
          rows.map((r) => WorkoutTemplate.fromMap(r)).toList();
    } catch (_) {}
  }

  Future<void> _loadLibrary() async {
    try {
      final rows = await _db.queryAll('exercises', orderBy: 'name ASC');
      _library = rows.map((r) => Exercise.fromMap(r)).toList();
    } catch (_) {}
  }

  Future<void> _loadPRs() async {
    // PRs derived from recent workouts' completed sets
    final prMap = <String, PersonalRecord>{};
    for (final w in _workouts) {
      final sets = await _db.loadSetsForWorkout(w.id);
      for (final s in sets) {
        if ((s['completed'] as int) == 1 && (s['weight'] as num) > 0) {
          final set = WorkoutSet.fromMap(s);
          final pr = PersonalRecord.fromSet(set, w.endTime ?? w.startTime);
          final existing = prMap[set.exerciseName];
          if (existing == null || pr.e1RMValue > existing.e1RMValue) {
            prMap[set.exerciseName] = pr;
          }
        }
      }
    }
    _prs = prMap.values.toList()
      ..sort((a, b) => b.e1RMValue.compareTo(a.e1RMValue));
  }

  Future<void> _resumeActiveWorkout() async {
    try {
      final active = await _db.loadActiveWorkout();
      if (active != null) {
        _activeWorkout = Workout.fromMap(active);
        final sets = await _db.loadSetsForWorkout(_activeWorkout!.id);
        _activeSets = sets.map((s) => WorkoutSet.fromMap(s)).toList();
      }
    } catch (_) {}
  }

  Future<Workout> startWorkout({String? name, String? templateId, List<String>? exerciseNames}) async {
    final workout = Workout(
      name: name,
      templateId: templateId,
      startTime: DateTime.now(),
      supersetMode: false,
    );

    // Scaffold with initial sets for template exercises
    if (exerciseNames != null && exerciseNames.isNotEmpty) {
      var setNum = 1;
      for (final en in exerciseNames) {
        _activeSets.add(WorkoutSet(
          exerciseId: en,
          exerciseName: en,
          setNumber: setNum++,
        ));
      }
    }

    _activeWorkout = workout;
    await _persistActive();
    notifyListeners();
    return workout;
  }

  Future<void> addSet(WorkoutSet set) async {
    if (_activeWorkout == null) return;
    _activeSets.add(set);
    await _persistActive();
    notifyListeners();
  }

  Future<void> updateSet(WorkoutSet set) async {
    final idx = _activeSets.indexWhere((s) => s.id == set.id);
    if (idx >= 0) {
      _activeSets[idx] = set;
      await _persistActive();
      notifyListeners();
    }
  }

  Future<void> removeSet(WorkoutSet set) async {
    _activeSets.removeWhere((s) => s.id == set.id);
    await _persistActive();
    notifyListeners();
  }

  Future<void> toggleSetComplete(WorkoutSet set) async {
    await updateSet(set.copyWith(completed: !set.completed));
  }

  Future<void> toggleSuperset() async {
    if (_activeWorkout == null) return;
    _activeWorkout = Workout(
      id: _activeWorkout!.id,
      name: _activeWorkout!.name,
      startTime: _activeWorkout!.startTime,
      sets: _activeSets,
      supersetMode: !_activeWorkout!.supersetMode,
    );
    await _persistActive();
    notifyListeners();
  }

  Future<void> _persistActive() async {
    if (_activeWorkout == null) return;
    await _db.saveWorkout(_activeWorkout!, _activeSets);
  }

  Future<Results> finishWorkout() async {
    if (_activeWorkout == null) {
      return Results(0, 0, 0);
    }
    final workout = _activeWorkout!;
    workout.finalize();

    // Award XP
    final xpEarned = await _awardWorkoutXp(workout);
    workout.xpEarned = xpEarned;

    await _db.saveWorkout(workout, _activeSets);
    await _sync.writeLocal(
        'workouts', 'workout', workout.id, workout.toMap());
    for (final s in _activeSets) {
      await _sync.writeLocal('workout_sets', 'workout_set', s.id, s.toMap());
    }

    _workouts.insert(0, workout);
    _activeWorkout = null;
    _activeSets = [];
    notifyListeners();
    await _loadPRs();

    return Results(workout.totalVolume, workout.estimatedCalories, xpEarned);
  }

  Future<int> _awardWorkoutXp(Workout workout) async {
    var total = 0;
    final bonusBonus = _activeSets.where((s) => s.completed).length * 2;
    total += bonusBonus;
    total += 35;
    total = await _xp.award(
      baseAmount: total,
      source: 'workout',
      description: workout.name ?? 'Workout session',
    );
    return total;
  }

  Future<void> cancelWorkout() async {
    if (_activeWorkout == null) return;
    await _db.deleteById('workouts', _activeWorkout!.id);
    await _db.deleteById('workout_sets', _activeWorkout!.id);
    _activeWorkout = null;
    _activeSets = [];
    notifyListeners();
  }

  Future<void> saveTemplate(WorkoutTemplate template) async {
    await _db.upsert('templates', template.toMap());
    await _sync.writeLocal('templates', 'template', template.id, template.toMap());
    await _loadTemplates();
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    await _db.deleteById('templates', id);
    await _sync.deleteLocal('templates', 'template', id);
    await _loadTemplates();
    notifyListeners();
  }

  Future<void> addCustomExercise(Exercise exercise) async {
    await _db.upsert('exercises', exercise.toMap());
    _library.add(exercise);
    notifyListeners();
  }

  Future<void> deleteCustomExercise(String id) async {
    await _db.deleteById('exercises', id);
    _library.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Public getters
  List<PersonalRecord> get personalRecords => List.unmodifiable(_prs);
  List<Workout> get history => List.unmodifiable(_workouts);
}

class Results {
  final double volume;
  final int calories;
  final int xp;
  Results(this.volume, this.calories, this.xp);
}
