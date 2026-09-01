import 'package:flutter/foundation.dart';

import '../models/streak.dart';
import '../services/local_db_service.dart';

class StreakProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;

  List<Streak> _streaks = [];

  List<Streak> get streaks => List.unmodifiable(_streaks);

  Streak? streakOf(String type) {
    for (final s in _streaks) {
      if (s.streakType == type) return s;
    }
    return null;
  }

  int get longestStreak =>
      _streaks.fold(0, (max, s) => s.longestCount > max ? s.longestCount : max);

  int get totalCurrentStreak {
    int total = 0;
    for (final s in _streaks) {
      total += s.currentCount;
    }
    return total;
  }

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    try {
      final rows = await _db.queryAll('streaks');
      _streaks = rows.map((r) => Streak.fromMap(r)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> register(SyncVisibility type) async {
    var streak = streakOf(type.name);
    final now = DateTime.now();
    if (streak != null) {
      // Break if missed a day (will reset appropriately)
      if (streak.isBroken()) {
        streak = streak.breakStreak();
        await _save(streak);
      }
      streak = streak.registerCompletion();
      await _save(streak);
    } else {
      streak = Streak(
        userId: 'local',
        streakType: type.name,
        currentCount: 1,
        longestCount: 1,
        lastCompletedAt: now,
      );
      await _save(streak);
    }
    notifyListeners();
  }

  Future<void> _save(Streak streak) async {
    await _db.upsert('streaks', streak.toMap());
    // Replace in list
    final idx = _streaks.indexWhere((s) => s.id == streak.id);
    if (idx >= 0) {
      _streaks[idx] = streak;
    } else {
      _streaks.add(streak);
    }
  }
}

enum SyncVisibility {
  workout,
  habit,
  study,
  water,
  daily,
}
