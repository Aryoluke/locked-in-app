import 'package:uuid/uuid.dart';

class XpTransaction {
  final String id;
  final int amount;
  final String source; // 'workout', 'habit', 'study', 'water', 'streak', 'login', 'pomodoro'
  final String? description;
  final DateTime timestamp;
  final bool isStreakBonus;

  XpTransaction({
    String? id,
    required this.amount,
    required this.source,
    this.description,
    DateTime? timestamp,
    this.isStreakBonus = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'source': source,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'is_streak_bonus': isStreakBonus ? 1 : 0,
      };

  factory XpTransaction.fromMap(Map<String, dynamic> map) => XpTransaction(
        id: map['id'] as String,
        amount: (map['amount'] as int),
        source: map['source'] as String,
        description: map['description'] as String?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        isStreakBonus: (map['is_streak_bonus'] as int?) == 1,
      );
}

class LevelInfo {
  final int level;
  final int xpAtLevel;
  final int xpForNext;
  final String title;

  LevelInfo({
    required this.level,
    required this.xpAtLevel,
    required this.xpForNext,
    required this.title,
  });

  double get progress {
    if (xpForNext <= 0) return 1.0;
    return (xpAtLevel / xpForNext).clamp(0.0, 1.0);
  }
}
