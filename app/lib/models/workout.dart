import 'dart:convert';

import 'package:uuid/uuid.dart';

class Exercise {
  final String id;
  final String name;
  final String bodyPart;
  final String? variation;
  final bool isCustom;

  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    this.variation,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'body_part': bodyPart,
        'variation': variation,
        'is_custom': isCustom ? 1 : 0,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as String,
        name: map['name'] as String,
        bodyPart: map['body_part'] as String,
        variation: map['variation'] as String?,
        isCustom: (map['is_custom'] as int?) == 1,
      );

  Exercise copyWith({String? variation}) => Exercise(
        id: id,
        name: name,
        bodyPart: bodyPart,
        variation: variation ?? this.variation,
        isCustom: isCustom,
      );
}

class WorkoutSet {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  int reps;
  double weight;
  bool completed;
  String? notes;
  final DateTime timestamp;

  WorkoutSet({
    String? id,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    this.reps = 0,
    this.weight = 0,
    this.completed = false,
    this.notes,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'set_number': setNumber,
        'reps': reps,
        'weight': weight,
        'completed': completed ? 1 : 0,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WorkoutSet.fromMap(Map<String, dynamic> map) => WorkoutSet(
        id: map['id'] as String,
        exerciseId: map['exercise_id'] as String,
        exerciseName: map['exercise_name'] as String,
        setNumber: (map['set_number'] as int),
        reps: (map['reps'] as int),
        weight: (map['weight'] as num).toDouble(),
        completed: (map['completed'] as int) == 1,
        notes: map['notes'] as String?,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );

  WorkoutSet copyWith({
    int? reps,
    double? weight,
    bool? completed,
    String? notes,
  }) =>
      WorkoutSet(
        id: id,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        setNumber: setNumber,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        completed: completed ?? this.completed,
        notes: notes ?? this.notes,
        timestamp: timestamp,
      );
}

class Workout {
  final String id;
  final String? name;
  final String? templateId;
  final DateTime startTime;
  DateTime? endTime;
  final List<WorkoutSet> sets;
  final bool supersetMode;
  double totalVolume;
  int estimatedCalories;
  int xpEarned;

  Workout({
    String? id,
    this.name,
    this.templateId,
    DateTime? startTime,
    this.endTime,
    this.sets = const [],
    this.supersetMode = false,
    this.totalVolume = 0,
    this.estimatedCalories = 0,
    this.xpEarned = 0,
  })  : id = id ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now();

  int get sessions => sets.isEmpty ? 0 : sets.map((s) => s.setNumber).reduce((a, b) => a > b ? a : b);
  int get exerciseCount => sets.map((s) => s.exerciseId).toSet().length;
  int get completedSets => sets.where((s) => s.completed).length;

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  double get volume => sets.where((s) => s.completed).fold(0.0, (sum, s) => sum + (s.reps * s.weight));

  void finalize() {
    endTime = DateTime.now();
    totalVolume = volume;
    calculatedCalories();
  }

  void calculatedCalories() {
    // Rough estimate: 0.1 kcal per kg lifted total volume, adjusted by duration
    estimatedCalories = (totalVolume * 0.1 + duration.inSeconds / 60 * 2).round();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'template_id': templateId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'superset_mode': supersetMode ? 1 : 0,
        'total_volume': totalVolume,
        'estimated_calories': estimatedCalories,
        'xp_earned': xpEarned,
      };

  factory Workout.fromMap(Map<String, dynamic> map) => Workout(
        id: map['id'] as String,
        name: map['name'] as String?,
        templateId: map['template_id'] as String?,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
        supersetMode: (map['superset_mode'] as int?) == 1,
        totalVolume: (map['total_volume'] as num?)?.toDouble() ?? 0,
        estimatedCalories: (map['estimated_calories'] as int?) ?? 0,
        xpEarned: (map['xp_earned'] as int?) ?? 0,
      );
}

class WorkoutTemplate {
  final String id;
  final String name;
  final List<String> exerciseNames;
  final List<(String, int, double)> exerciseDefaults;
  final String? notes;
  final int estimatedDurationMin;

  WorkoutTemplate({
    String? id,
    required this.name,
    this.exerciseNames = const [],
    this.exerciseDefaults = const [],
    this.notes,
    this.estimatedDurationMin = 45,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'exercise_names': jsonEncode(exerciseNames),
        'exercise_defaults': jsonEncode([
          for (final e in exerciseDefaults)
            {'exercise': e.$1, 'reps': e.$2, 'weight': e.$3}
        ]),
        'notes': notes,
        'estimated_duration_min': estimatedDurationMin,
      };

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map) {
    final defaultsList = map['exercise_defaults'] != null
        ? jsonDecode(map['exercise_defaults'] as String) as List
        : <dynamic>[];
    return WorkoutTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      exerciseNames: map['exercise_names'] != null
          ? List<String>.from(jsonDecode(map['exercise_names'] as String))
          : [],
      exerciseDefaults: [
        for (final d in defaultsList)
          (
            d['exercise'] as String,
            (d['reps'] as num).toInt(),
            (d['weight'] as num).toDouble(),
          )
      ],
      notes: map['notes'] as String?,
      estimatedDurationMin: (map['estimated_duration_min'] as int?) ?? 45,
    );
  }
}

class PersonalRecord {
  final String exerciseName;
  final double weight;
  final int reps;
  final String estimatedOneRepMax;
  final DateTime date;

  PersonalRecord({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.estimatedOneRepMax,
    required this.date,
  });

  // Numeric value for comparisons/sorting; the String field is for display.
  double get e1RMValue => double.tryParse(estimatedOneRepMax) ?? 0;

  factory PersonalRecord.fromSet(WorkoutSet set, DateTime date) {
    final e1rm = set.reps > 1 ? set.weight * (1 + set.reps / 30) : set.weight;
    return PersonalRecord(
      exerciseName: set.exerciseName,
      weight: set.weight,
      reps: set.reps,
      estimatedOneRepMax: e1rm.toStringAsFixed(1),
      date: date,
    );
  }
}
