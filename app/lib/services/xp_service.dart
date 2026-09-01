import 'dart:async';

import '../config/constants.dart';
import '../models/streak.dart';
import '../models/user.dart';
import '../models/xp.dart';
import 'local_db_service.dart';

class XpService {
  XpService._internal();
  static final XpService instance = XpService._internal();

  final LocalDbService _db = LocalDbService.instance;

  final StreamController<XpAward> _awardController =
      StreamController<XpAward>.broadcast();
  Stream<XpAward> get awards => _awardController.stream;

  List<XpTransaction> _transactions = [];
  int _totalXp = 0;
  int _currentLevel = 1;

  Future<void> init() async {
    await _reloadFromDb();
  }

  Future<void> _reloadFromDb() async {
    try {
      final rows = await _db.queryAll('xp_transactions', orderBy: 'timestamp DESC');
      _transactions = rows
          .map((r) => XpTransaction.fromMap({
                'id': r['id'],
                'amount': r['amount'],
                'source': r['source'],
                'description': r['description'],
                'timestamp': r['timestamp'],
                'is_streak_bonus': r['is_streak_bonus'],
              }))
          .toList();
      _calculateTotals();
    } catch (_) {}
  }

  void _calculateTotals() {
    _totalXp = _transactions.fold(0, (sum, t) => sum + t.amount);
    _currentLevel = _levelForXp(_totalXp);
  }

  int get totalXp => _totalXp;
  int get currentLevel => _currentLevel;
  List<XpTransaction> get history => List.unmodifiable(_transactions);

  int _levelForXp(int xp) {
    var level = 1;
    for (final threshold in AppConstants.levelThresholds) {
      if (xp >= threshold) {
        level = AppConstants.levelThresholds.indexOf(threshold) + 1;
      }
    }
    return level;
  }

  Future<int> award({
    required int baseAmount,
    required String source,
    String? description,
    int? currentStreak,
  }) async {
    var amount = baseAmount;
    var isStreakBonus = false;

    // Streak bonus multiplier for workouts & habits at LOCKED IN streaks
    if ((source == 'workout' || source == 'habit') && currentStreak != null) {
      if (currentStreak >= 21) {
        amount *= 3;
        isStreakBonus = true;
      } else if (currentStreak >= 14) {
        amount = (amount * 2.5).round();
        isStreakBonus = true;
      } else if (currentStreak >= 7) {
        amount = (amount * 2).round();
        isStreakBonus = true;
      }
    }

    final tx = XpTransaction(
      amount: amount,
      source: source,
      description: description,
      isStreakBonus: isStreakBonus,
    );

    _transactions.insert(0, tx);
    _totalXp += amount;

    final prevLevel = _currentLevel;
    _currentLevel = _levelForXp(_totalXp);
    final leveledUp = _currentLevel > prevLevel;

    // Persist locally
    await _db.upsert('xp_transactions', tx.toMap());

    _awardController.add(XpAward(
      transaction: tx,
      totalXp: _totalXp,
      level: _currentLevel,
      leveledUp: leveledUp,
    ));

    return amount;
  }

  int get xpForCurrentLevel {
    final thresholds = AppConstants.levelThresholds;
    if (_currentLevel - 1 < thresholds.length) {
      return thresholds[_currentLevel - 1];
    }
    return (_currentLevel - 1) * 2500;
  }

  int get xpForNextLevel {
    final thresholds = AppConstants.levelThresholds;
    if (_currentLevel < thresholds.length) {
      return thresholds[_currentLevel];
    }
    return _currentLevel * 2500;
  }

  double get progressToNextLevel {
    final needed = xpForNextLevel - xpForCurrentLevel;
    if (needed <= 0) return 1.0;
    return ((_totalXp - xpForCurrentLevel) / needed).clamp(0.0, 1.0);
  }
}

class XpAward {
  final XpTransaction transaction;
  final int totalXp;
  final int level;
  final bool leveledUp;

  XpAward({
    required this.transaction,
    required this.totalXp,
    required this.level,
    required this.leveledUp,
  });
}
