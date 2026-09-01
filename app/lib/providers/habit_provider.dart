import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../services/xp_service.dart';

class HabitProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;
  final SyncService _sync = SyncService.instance;
  final XpService _xp = XpService.instance;

  List<Habit> _habits = [];
  Map<String, List<HabitCompletion>> _completions = {};
  bool _loading = false;

  List<Habit> get habits => List.unmodifiable(_habits);

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    _loading = true;
    try {
      final rows = await _db.queryAll('habits', orderBy: 'sort_order ASC');
      _habits = rows.where((r) => (r['enabled'] as int?) != 0)
          .map((r) => Habit.fromMap(r))
          .toList();

      _completions.clear();
      for (final h in _habits) {
        final compRows = await _db.queryAll('habit_completions',
            where: 'habit_id = ? AND date LIKE ?',
            whereArgs: [h.id, '${_dateKey(DateTime.now())}%']);
        _completions[h.id] =
            compRows.map((r) => HabitCompletion.fromMap(r)).toList();
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  bool isCompletedToday(Habit habit) {
    final list = _completions[habit.id];
    if (list == null) return false;
    final todayKey = _dateKey(DateTime.now());
    return list.where((c) {
      final cKey = _dateKey(c.date);
      return cKey == todayKey;
    }).fold(0, (sum, c) => sum + c.count) >= habit.targetCount;
  }

  int completedCountToday(Habit habit) {
    final list = _completions[habit.id];
    if (list == null) return 0;
    return list.where((c) => _dateKey(c.date) == _dateKey(DateTime.now()))
        .fold(0, (sum, c) => sum + c.count);
  }

  double get todayProgress {
    if (_habits.isEmpty) return 0;
    final done = _habits.where((h) => isCompletedToday(h)).length;
    return done / _habits.length;
  }

  Future<void> toggleHabit(Habit habit) async {
    final todayKey = _dateKey(DateTime.now());

    if (isCompletedToday(habit)) {
      // Undo today's completion
      final rows = await _db.queryAll('habit_completions',
          where: 'habit_id = ? AND date LIKE ?',
          whereArgs: [habit.id, '$todayKey%']);
      for (final row in rows) {
        await _db.deleteById('habit_completions', row['id'] as String);
      }
      _completions[habit.id] = [];
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final completion = HabitCompletion(
      habitId: habit.id,
      date: now,
      count: 1,
    );
    await _db.upsert('habit_completions', completion.toMap());
    await _sync.writeLocal(
        'habit_completions', 'habit_completion', completion.id, completion.toMap());

    // Update habit streak counters
    final isYesterday = await _wasCompletedOnDate(habit.id, now.subtract(const Duration(days: 1)));
    final newStreak = isYesterday ? habit.currentStreak + 1 : 1;
    final updated = habit.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
      totalCompletions: habit.totalCompletions + 1,
    );
    await _updateHabit(updated);

    // Award XP
    await _xp.award(
      baseAmount: 10,
      source: 'habit',
      description: habit.name,
      currentStreak: newStreak,
    );

    _completions[habit.id] = [completion];
    notifyListeners();
  }

  Future<bool> _wasCompletedOnDate(String habitId, DateTime date) async {
    final prefix = _dateKey(date);
    final rows = await _db.queryAll('habit_completions',
        where: 'habit_id = ? AND date LIKE ?',
        whereArgs: [habitId, '$prefix%']);
    return rows.isNotEmpty;
  }

  Future<void> _updateHabit(Habit habit) async {
    _habits = _habits.map((h) => h.id == habit.id ? habit : h).toList();
    await _db.upsert('habits', habit.toMap());
    await _sync.writeLocal('habits', 'habit', habit.id, habit.toMap());
  }

  Future<void> addHabit(Habit habit) async {
    await _db.upsert('habits', habit.toMap());
    await _sync.writeLocal('habits', 'habit', habit.id, habit.toMap());
    _habits.add(habit);
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    await _db.deleteById('habits', id);
    await _sync.deleteLocal('habits', 'habit', id);
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  Future<void> reorder(List<Habit> newOrder) async {
    for (var i = 0; i < newOrder.length; i++) {
      await _db.upsert('habits', {...newOrder[i].toMap(), 'sort_order': i});
    }
    _habits = newOrder;
    notifyListeners();
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
