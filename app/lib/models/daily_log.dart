import 'package:uuid/uuid.dart';

class DailyLog {
  final String id;
  final DateTime date;
  double waterLiters;
  int steps;
  int sleepHours;
  int sleepQuality; // 1-5
  int energyLevel; // 1-5
  int mood; // 1-5
  int motivation; // 1-5
  double? bodyWeight;
  int muscleSoreness; // 1-5
  List<String> notes;

  DailyLog({
    String? id,
    DateTime? date,
    this.waterLiters = 0,
    this.steps = 0,
    this.sleepHours = 0,
    this.sleepQuality = 3,
    this.energyLevel = 3,
    this.mood = 3,
    this.motivation = 3,
    this.bodyWeight,
    this.muscleSoreness = 1,
    this.notes = const [],
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  double get waterProgress => (waterLiters / 3.0).clamp(0.0, 1.0);
  bool get isHydrated => waterLiters >= 3.0;

  String get recoveryStatus {
    final score = (sleepQuality * 2 + (5 - muscleSoreness)) / 3;
    if (score >= 4) return 'Primed';
    if (score >= 3) return 'Good';
    if (score >= 2) return 'Tired';
    return 'Drained';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'water_liters': waterLiters,
        'steps': steps,
        'sleep_hours': sleepHours,
        'sleep_quality': sleepQuality,
        'energy_level': energyLevel,
        'mood': mood,
        'motivation': motivation,
        'body_weight': bodyWeight,
        'muscle_soreness': muscleSoreness,
        'notes': notes.join('|'),
      };

  factory DailyLog.fromMap(Map<String, dynamic> map) => DailyLog(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        waterLiters: (map['water_liters'] as num?)?.toDouble() ?? 0,
        steps: (map['steps'] as int?) ?? 0,
        sleepHours: (map['sleep_hours'] as int?) ?? 0,
        sleepQuality: (map['sleep_quality'] as int?) ?? 3,
        energyLevel: (map['energy_level'] as int?) ?? 3,
        mood: (map['mood'] as int?) ?? 3,
        motivation: (map['motivation'] as int?) ?? 3,
        bodyWeight: (map['body_weight'] as num?)?.toDouble(),
        muscleSoreness: (map['muscle_soreness'] as int?) ?? 1,
        notes: (map['notes'] as String? ?? '').split('|').where((n) => n.isNotEmpty).toList(),
      );

  DailyLog copyWith({
    double? waterLiters,
    int? steps,
    int? sleepHours,
    int? sleepQuality,
    int? energyLevel,
    int? mood,
    int? motivation,
    double? bodyWeight,
    int? muscleSoreness,
    List<String>? notes,
  }) =>
      DailyLog(
        id: id,
        date: date,
        waterLiters: waterLiters ?? this.waterLiters,
        steps: steps ?? this.steps,
        sleepHours: sleepHours ?? this.sleepHours,
        sleepQuality: sleepQuality ?? this.sleepQuality,
        energyLevel: energyLevel ?? this.energyLevel,
        mood: mood ?? this.mood,
        motivation: motivation ?? this.motivation,
        bodyWeight: bodyWeight ?? this.bodyWeight,
        muscleSoreness: muscleSoreness ?? this.muscleSoreness,
        notes: notes ?? this.notes,
      );
}
