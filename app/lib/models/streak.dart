import 'package:uuid/uuid.dart';

class Streak {
  final String id;
  final String userId;
  final String streakType; // 'workout', 'habit', 'study', 'water', 'daily'
  final int currentCount;
  final int longestCount;
  final DateTime? lastCompletedAt;
  final DateTime startDate;

  Streak({
    String? id,
    required this.userId,
    required this.streakType,
    this.currentCount = 0,
    this.longestCount = 0,
    this.lastCompletedAt,
    DateTime? startDate,
  })  : id = id ?? const Uuid().v4(),
        startDate = startDate ?? DateTime.now();

  bool isActiveToday() {
    if (lastCompletedAt == null) return false;
    final now = DateTime.now();
    final last = lastCompletedAt!;
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  bool isBroken() {
    if (lastCompletedAt == null) return currentCount > 0;
    final diff = DateTime.now().difference(lastCompletedAt!).inDays;
    return diff > 1;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'streak_type': streakType,
        'current_count': currentCount,
        'longest_count': longestCount,
        'last_completed_at': lastCompletedAt?.toIso8601String(),
        'start_date': startDate.toIso8601String(),
      };

  factory Streak.fromMap(Map<String, dynamic> map) => Streak(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        streakType: map['streak_type'] as String,
        currentCount: (map['current_count'] as int?) ?? 0,
        longestCount: (map['longest_count'] as int?) ?? 0,
        lastCompletedAt: map['last_completed_at'] != null
            ? DateTime.parse(map['last_completed_at'] as String)
            : null,
        startDate: DateTime.parse(
            map['start_date'] as String? ?? DateTime.now().toIso8601String()),
      );

  Streak registerCompletion() {
    final now = DateTime.now();
    final newCount = currentCount + 1;
    return Streak(
      id: id,
      userId: userId,
      streakType: streakType,
      currentCount: newCount,
      longestCount: newCount > longestCount ? newCount : longestCount,
      lastCompletedAt: now,
      startDate: startDate,
    );
  }

  Streak breakStreak() {
    return Streak(
      id: id,
      userId: userId,
      streakType: streakType,
      currentCount: 0,
      longestCount: longestCount,
      lastCompletedAt: null,
      startDate: startDate,
    );
  }
}
