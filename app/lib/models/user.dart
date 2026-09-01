import 'dart:convert';

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final double? heightCm;
  final double? weightKg;
  final String? bodyType; // 'sleeper', 'bulk', 'hybrid'
  final String? fitnessGoal;
  final String? dietaryPreference;
  final String? activityLevel;
  final String? sleepSchedule;
  final List<String> availableEquipment;
  final List<String> goals;
  final bool onboardingComplete;
  final int totalXp;
  final int currentLevel;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, bool> privacySettings;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.bodyType,
    this.fitnessGoal,
    this.dietaryPreference,
    this.activityLevel,
    this.sleepSchedule,
    this.availableEquipment = const [],
    this.goals = const [],
    this.onboardingComplete = false,
    this.totalXp = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.createdAt,
    required this.updatedAt,
    this.privacySettings = const {
      'workouts': true,
      'habits': true,
      'study': true,
      'body': false,
      'social': true,
    },
  });

  String get lockInLevel {
    if (currentStreak >= 60) return 'TRANSCENDENT';
    if (currentStreak >= 30) return 'UNSTOPPABLE';
    if (currentStreak >= 21) return 'LOCKED IN';
    if (currentStreak >= 14) return 'In The Zone';
    if (currentStreak >= 7) return 'Focused';
    if (currentStreak >= 3) return 'Warming Up';
    return 'Asleep';
  }

  int get xpForNextLevel {
    final thresholds = [0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5200, 6500, 8000, 10000, 12500, 15500, 19000, 23000, 28000, 34000, 41000];
    if (currentLevel - 1 < thresholds.length) {
      return thresholds[currentLevel - 1];
    }
    return currentLevel * 2500;
  }

  int get xpForNextLevelMax {
    final thresholds = [0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5200, 6500, 8000, 10000, 12500, 15500, 19000, 23000, 28000, 34000, 41000];
    if (currentLevel < thresholds.length) {
      return thresholds[currentLevel];
    }
    return (currentLevel + 1) * 2500;
  }

  double get xpProgress {
    final needed = xpForNextLevelMax - xpForNextLevel;
    if (needed <= 0) return 1.0;
    return ((totalXp - xpForNextLevel) / needed).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'body_type': bodyType,
      'fitness_goal': fitnessGoal,
      'dietary_preference': dietaryPreference,
      'activity_level': activityLevel,
      'sleep_schedule': sleepSchedule,
      'available_equipment': jsonEncode(availableEquipment),
      'goals': jsonEncode(goals),
      'onboarding_complete': onboardingComplete ? 1 : 0,
      'total_xp': totalXp,
      'current_level': currentLevel,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'privacy_settings': jsonEncode(privacySettings),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      bodyType: map['body_type'] as String?,
      fitnessGoal: map['fitness_goal'] as String?,
      dietaryPreference: map['dietary_preference'] as String?,
      activityLevel: map['activity_level'] as String?,
      sleepSchedule: map['sleep_schedule'] as String?,
      availableEquipment: map['available_equipment'] != null
          ? List<String>.from(jsonDecode(map['available_equipment'] as String))
          : [],
      goals: map['goals'] != null
          ? List<String>.from(jsonDecode(map['goals'] as String))
          : [],
      onboardingComplete: (map['onboarding_complete'] as int?) == 1,
      totalXp: (map['total_xp'] as int?) ?? 0,
      currentLevel: (map['current_level'] as int?) ?? 1,
      currentStreak: (map['current_streak'] as int?) ?? 0,
      longestStreak: (map['longest_streak'] as int?) ?? 0,
      createdAt: DateTime.parse(
          map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          map['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      privacySettings: map['privacy_settings'] != null
          ? Map<String, bool>.from(
              jsonDecode(map['privacy_settings'] as String))
          : {
              'workouts': true,
              'habits': true,
              'study': true,
              'body': false,
              'social': true,
            },
    );
  }

  User copyWith({
    String? displayName,
    String? avatarUrl,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    String? bodyType,
    String? fitnessGoal,
    String? dietaryPreference,
    String? activityLevel,
    String? sleepSchedule,
    List<String>? availableEquipment,
    List<String>? goals,
    bool? onboardingComplete,
    int? totalXp,
    int? currentLevel,
    int? currentStreak,
    int? longestStreak,
    Map<String, bool>? privacySettings,
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bodyType: bodyType ?? this.bodyType,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      activityLevel: activityLevel ?? this.activityLevel,
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      goals: goals ?? this.goals,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      privacySettings: privacySettings ?? this.privacySettings,
    );
  }
}
