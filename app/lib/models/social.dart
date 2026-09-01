import 'package:uuid/uuid.dart';

class Friend {
  final String id;
  final String name;
  final String? avatarUrl;
  final int xp;
  final int level;
  final int currentStreak;
  final bool isOnline;
  final DateTime lastActive;

  Friend({
    String? id,
    required this.name,
    this.avatarUrl,
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.isOnline = false,
    required this.lastActive,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'xp': xp,
        'level': level,
        'current_streak': currentStreak,
        'is_online': isOnline ? 1 : 0,
        'last_active': lastActive.toIso8601String(),
      };

  factory Friend.fromMap(Map<String, dynamic> map) => Friend(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarUrl: map['avatar_url'] as String?,
        xp: (map['xp'] as int?) ?? 0,
        level: (map['level'] as int?) ?? 1,
        currentStreak: (map['current_streak'] as int?) ?? 0,
        isOnline: (map['is_online'] as int?) == 1,
        lastActive: DateTime.parse(map['last_active'] as String),
      );
}

enum ActivityType {
  workout,
  habit,
  study,
  water,
  streak,
  levelUp,
  pomodoro,
}

class ActivityEvent {
  final String id;
  final String userId;
  final String userName;
  final ActivityType type;
  final String message;
  final int xpEarned;
  final DateTime timestamp;
  final String? workoutName;

  ActivityEvent({
    String? id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.message,
    this.xpEarned = 0,
    DateTime? timestamp,
    this.workoutName,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  IconGlyph get glyph {
    switch (type) {
      case ActivityType.workout:
        return IconGlyph.fitness;
      case ActivityType.habit:
        return IconGlyph.habit;
      case ActivityType.study:
        return IconGlyph.book;
      case ActivityType.water:
        return IconGlyph.water;
      case ActivityType.streak:
        return IconGlyph.flame;
      case ActivityType.levelUp:
        return IconGlyph.star;
      case ActivityType.pomodoro:
        return IconGlyph.timer;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'type': type.name,
        'message': message,
        'xp_earned': xpEarned,
        'timestamp': timestamp.toIso8601String(),
        'workout_name': workoutName,
      };

  factory ActivityEvent.fromMap(Map<String, dynamic> map) => ActivityEvent(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        userName: map['user_name'] as String,
        type: ActivityType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => ActivityType.workout,
        ),
        message: map['message'] as String,
        xpEarned: (map['xp_earned'] as int?) ?? 0,
        timestamp: DateTime.parse(map['timestamp'] as String),
        workoutName: map['workout_name'] as String?,
      );
}

enum IconGlyph {
  fitness,
  habit,
  book,
  water,
  flame,
  star,
  timer,
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final int xp;
  final int level;
  final int streak;
  final bool isUser;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.xp,
    required this.level,
    required this.streak,
    this.isUser = false,
  });

  Map<String, dynamic> toMap() => {
        'rank': rank,
        'user_id': userId,
        'name': name,
        'xp': xp,
        'level': level,
        'streak': streak,
        'is_user': isUser ? 1 : 0,
      };

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, {required bool isUser}) =>
      LeaderboardEntry(
        rank: (map['rank'] as int),
        userId: map['user_id'] as String,
        name: map['name'] as String,
        xp: (map['xp'] as int),
        level: (map['level'] as int),
        streak: (map['streak'] as int?) ?? 0,
        isUser: isUser,
      );
}
