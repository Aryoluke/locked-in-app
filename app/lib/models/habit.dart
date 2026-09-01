import 'package:uuid/uuid.dart';

class Habit {
  final String id;
  final String name;
  final String icon; // emoji
  final String category; // 'health', 'mind', 'discipline', 'social', 'custom'
  final String frequency; // 'daily', 'weekdays', 'weekly'
  final int targetCount;
  final DateTime createdAt;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final bool enabled;
  final int sortOrder;

  Habit({
    String? id,
    required this.name,
    this.icon = '✅',
    this.category = 'discipline',
    this.frequency = 'daily',
    this.targetCount = 1,
    DateTime? createdAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompletions = 0,
    this.enabled = true,
    this.sortOrder = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'category': category,
        'frequency': frequency,
        'target_count': targetCount,
        'created_at': createdAt.toIso8601String(),
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'total_completions': totalCompletions,
        'enabled': enabled ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String? ?? '✅',
        category: map['category'] as String? ?? 'discipline',
        frequency: map['frequency'] as String? ?? 'daily',
        targetCount: (map['target_count'] as int?) ?? 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        currentStreak: (map['current_streak'] as int?) ?? 0,
        longestStreak: (map['longest_streak'] as int?) ?? 0,
        totalCompletions: (map['total_completions'] as int?) ?? 0,
        enabled: (map['enabled'] as int?) != 0,
        sortOrder: (map['sort_order'] as int?) ?? 0,
      );

  Habit copyWith({
    String? name,
    String? icon,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletions,
    bool? enabled,
  }) =>
      Habit(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        category: category,
        frequency: frequency,
        targetCount: targetCount,
        createdAt: createdAt,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        totalCompletions: totalCompletions ?? this.totalCompletions,
        enabled: enabled ?? this.enabled,
        sortOrder: sortOrder,
      );
}

class HabitCompletion {
  final String id;
  final String habitId;
  final DateTime date;
  final int count;

  HabitCompletion({
    String? id,
    required this.habitId,
    required this.date,
    this.count = 1,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'habit_id': habitId,
        'date': date.toIso8601String(),
        'count': count,
      };

  factory HabitCompletion.fromMap(Map<String, dynamic> map) =>
      HabitCompletion(
        id: map['id'] as String,
        habitId: map['habit_id'] as String,
        date: DateTime.parse(map['date'] as String),
        count: (map['count'] as int?) ?? 1,
      );
}
