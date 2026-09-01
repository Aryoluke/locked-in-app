import 'package:uuid/uuid.dart';

class StudyLog {
  final String id;
  final String subject;
  final String? topic;
  final int minutes;
  final int pomodoros;
  final DateTime date;
  final String? notes;
  final int focusScore; // 1-10

  StudyLog({
    String? id,
    required this.subject,
    this.topic,
    required this.minutes,
    this.pomodoros = 0,
    DateTime? date,
    this.notes,
    this.focusScore = 5,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  double get hours => minutes / 60;

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'topic': topic,
        'minutes': minutes,
        'pomodoros': pomodoros,
        'date': date.toIso8601String(),
        'notes': notes,
        'focus_score': focusScore,
      };

  factory StudyLog.fromMap(Map<String, dynamic> map) => StudyLog(
        id: map['id'] as String,
        subject: map['subject'] as String,
        topic: map['topic'] as String?,
        minutes: (map['minutes'] as int),
        pomodoros: (map['pomodoros'] as int?) ?? 0,
        date: DateTime.parse(map['date'] as String),
        notes: map['notes'] as String?,
        focusScore: (map['focus_score'] as int?) ?? 5,
      );
}

class Subject {
  final String id;
  final String name;
  final String? colorHex;
  final int totalMinutes;
  final int currentStreak;
  final int longestStreak;

  Subject({
    String? id,
    required this.name,
    this.colorHex,
    this.totalMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  }) : id = id ?? const Uuid().v4();

  double get hours => totalMinutes / 60;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color_hex': colorHex,
        'total_minutes': totalMinutes,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
      };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
        id: map['id'] as String,
        name: map['name'] as String,
        colorHex: map['color_hex'] as String?,
        totalMinutes: (map['total_minutes'] as int?) ?? 0,
        currentStreak: (map['current_streak'] as int?) ?? 0,
        longestStreak: (map['longest_streak'] as int?) ?? 0,
      );

  Subject addMinutes(int minutes) => Subject(
        id: id,
        name: name,
        colorHex: colorHex,
        totalMinutes: totalMinutes + minutes,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
      );
}
