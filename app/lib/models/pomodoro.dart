import 'package:uuid/uuid.dart';

class PomodoroSession {
  final String id;
  final String type; // 'work', 'short_break', 'long_break'
  final String? tag; // 'study', 'work', 'deep_work', 'creation'
  final int plannedMinutes;
  final int actualSeconds;
  final DateTime startTime;
  final DateTime? endTime;
  final bool completed;

  PomodoroSession({
    String? id,
    required this.type,
    this.tag,
    required this.plannedMinutes,
    this.actualSeconds = 0,
    DateTime? startTime,
    this.endTime,
    this.completed = false,
  })  : id = id ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now();

  Duration get elapsed => Duration(seconds: actualSeconds);
  Duration get remaining {
    final total = Duration(minutes: plannedMinutes);
    final el = elapsed;
    final rem = total - el;
    return rem.isNegative ? Duration.zero : rem;
  }

  double get progress {
    final total = plannedMinutes * 60;
    if (total <= 0) return 0;
    return (actualSeconds / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'tag': tag,
        'planned_minutes': plannedMinutes,
        'actual_seconds': actualSeconds,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'completed': completed ? 1 : 0,
      };

  factory PomodoroSession.fromMap(Map<String, dynamic> map) =>
      PomodoroSession(
        id: map['id'] as String,
        type: map['type'] as String,
        tag: map['tag'] as String?,
        plannedMinutes: (map['planned_minutes'] as int),
        actualSeconds: (map['actual_seconds'] as int?) ?? 0,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
        completed: (map['completed'] as int?) == 1,
      );
}

class MoodCheckIn {
  final String id;
  final int energy; // 1-5
  final int mood; // 1-5
  final int motivation; // 1-5
  final DateTime timestamp;
  final String? note;

  MoodCheckIn({
    String? id,
    required this.energy,
    required this.mood,
    required this.motivation,
    DateTime? timestamp,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  int get totalScore => energy + mood + motivation;

  Map<String, dynamic> toMap() => {
        'id': id,
        'energy': energy,
        'mood': mood,
        'motivation': motivation,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory MoodCheckIn.fromMap(Map<String, dynamic> map) => MoodCheckIn(
        id: map['id'] as String,
        energy: (map['energy'] as int),
        mood: (map['mood'] as int),
        motivation: (map['motivation'] as int),
        timestamp: DateTime.parse(map['timestamp'] as String),
        note: map['note'] as String?,
      );
}
