import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/pomodoro.dart';
import '../models/study_log.dart';
import '../services/local_db_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../services/xp_service.dart';

class StudyProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;
  final SyncService _sync = SyncService.instance;
  final XpService _xp = XpService.instance;
  final NotificationService _notifications = NotificationService.instance;

  List<StudyLog> _studyLogs = [];
  List<Subject> _subjects = [];
  List<MoodCheckIn> _moodHistory = [];

  // Pomodoro state
  bool _pomodoroRunning = false;
  bool _pomodoroPaused = false;
  Duration _pomodoroRemaining = const Duration(minutes: 25);
  Duration _pomodoroTotal = const Duration(minutes: 25);
  String _pomodoroPhase = 'work'; // work | short_break | long_break
  int _completedPomodoros = 0;
  String? _currentTag;
  Timer? _pomodoroTimer;
  DateTime? _phaseStart;
  PomodoroSession? _currentSession;

  List<StudyLog> get studyLogs => List.unmodifiable(_studyLogs);
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<MoodCheckIn> get moodHistory => List.unmodifiable(_moodHistory);

  bool get pomodoroRunning => _pomodoroRunning;
  bool get pomodoroPaused => _pomodoroPaused;
  Duration get pomodoroRemaining => _pomodoroRemaining;
  Duration get pomodoroTotal => _pomodoroTotal;
  String get pomodoroPhase => _pomodoroPhase;
  int get completedPomodoros => _completedPomodoros;
  String? get currentTag => _currentTag;
  PomodoroSession? get currentSession => _currentSession;

  double get pomodoroProgress {
    final totalSec = _pomodoroTotal.inSeconds;
    if (totalSec <= 0) return 0;
    return ((totalSec - _pomodoroRemaining.inSeconds) / totalSec)
        .clamp(0.0, 1.0);
  }

  Future<void> init() async {
    await loadStudyLogs();
    await loadSubjects();
    await loadMood();
  }

  Future<void> loadStudyLogs() async {
    try {
      final rows = await _db.queryAll('study_logs', orderBy: 'date DESC');
      _studyLogs = rows.map((r) => StudyLog.fromMap(r)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadSubjects() async {
    try {
      final rows = await _db.queryAll('subjects', orderBy: 'name ASC');
      _subjects = rows.map((r) => Subject.fromMap(r)).toList();
      if (_subjects.isEmpty) {
        _subjects = [
          Subject(name: 'Maths'),
          Subject(name: 'Science'),
          Subject(name: 'Languages'),
          Subject(name: 'Other'),
        ];
        for (final s in _subjects) {
          await _db.upsert('subjects', s.toMap());
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadMood() async {
    try {
      final rows = await _db.queryAll('mood_checkins', orderBy: 'timestamp DESC');
      _moodHistory = rows.map((r) => MoodCheckIn.fromMap(r)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<Subject> addSubject(String name) async {
    final subject = Subject(name: name);
    await _db.upsert('subjects', subject.toMap());
    await _sync.writeLocal('subjects', 'subject', subject.id, subject.toMap());
    _subjects.add(subject);
    notifyListeners();
    return subject;
  }

  Future<void> logStudy({
    required String subject,
    String? topic,
    int minutes = 25,
    int pomodoros = 1,
    String? notes,
    int focusScore = 5,
  }) async {
    final log = StudyLog(
      subject: subject,
      topic: topic,
      minutes: minutes,
      pomodoros: pomodoros,
      notes: notes,
      focusScore: focusScore,
    );
    await _db.upsert('study_logs', log.toMap());
    await _sync.writeLocal('study_logs', 'study_log', log.id, log.toMap());
    _studyLogs.insert(0, log);

    // Update subject totals
    final idx = _subjects.indexWhere((s) => s.name.toLowerCase() == subject.toLowerCase());
    if (idx >= 0) {
      final updated = _subjects[idx].addMinutes(minutes);
      _subjects[idx] = updated;
      await _db.upsert('subjects', updated.toMap());
      await _sync.writeLocal('subjects', 'subject', updated.id, updated.toMap());
    }

    // Award XP
    final xpForHours = (minutes / 60 * 25).round();
    await _xp.award(
      baseAmount: max(xpForHours, 10),
      source: 'study',
      description: '$subject study session',
    );

    notifyListeners();
  }

  // ===== Mood =====
  Future<void> checkInMood(int energy, int mood, int motivation, {String? note}) async {
    final checkIn = MoodCheckIn(
      energy: energy,
      mood: mood,
      motivation: motivation,
      note: note,
    );
    await _db.upsert('mood_checkins', checkIn.toMap());
    await _sync.writeLocal('mood_checkins', 'mood_checkin', checkIn.id, checkIn.toMap());
    _moodHistory.insert(0, checkIn);
    notifyListeners();
  }

  // ===== Pomodoro =====
  void startPomodoro({int minutes = AppConstants.pomodoroWorkMinutes, String? tag}) {
    _pomodoroRunning = true;
    _pomodoroPaused = false;
    _pomodoroPhase = 'work';
    _pomodoroTotal = Duration(minutes: minutes);
    _pomodoroRemaining = _pomodoroTotal;
    _currentTag = tag;
    _currentSession = PomodoroSession(
      type: 'work',
      tag: tag,
      plannedMinutes: minutes,
    );
    _phaseStart = DateTime.now();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _pomodoroTimer?.cancel();
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_pomodoroPaused || !_pomodoroRunning) return;
      if (_pomodoroRemaining.inSeconds <= 1) {
        _onPhaseComplete();
      } else {
        _pomodoroRemaining -= const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void pausePomodoro() {
    if (!_pomodoroRunning) return;
    _pomodoroPaused = !_pomodoroPaused;
    notifyListeners();
  }

  void resetPomodoro() {
    _pomodoroTimer?.cancel();
    _pomodoroRunning = false;
    _pomodoroPaused = false;
    _pomodoroPhase = 'work';
    _pomodoroTotal = const Duration(minutes: AppConstants.pomodoroWorkMinutes);
    _pomodoroRemaining = _pomodoroTotal;
    _currentSession = null;
    notifyListeners();
  }

  Future<void> _onPhaseComplete() async {
    // Persist completed work session
    if (_currentSession != null && _pomodoroPhase == 'work') {
      _completedPomodoros++;
      final session = PomodoroSession(
        id: _currentSession!.id,
        type: 'work',
        tag: _currentTag,
        plannedMinutes: _pomodoroTotal.inMinutes,
        actualSeconds: _pomodoroTotal.inSeconds,
        startTime: _phaseStart ?? DateTime.now(),
        endTime: DateTime.now(),
        completed: true,
      );
      await _db.upsert('pomodoro_sessions', session.toMap());
      await _sync.writeLocal('pomodoro_sessions', 'pomodoro', session.id, session.toMap());

      await _xp.award(
        baseAmount: 15,
        source: 'pomodoro',
        description: 'Pomodoro completed',
      );

      // Log study time
      await logStudy(
        subject: _currentTag ?? 'General',
        minutes: _pomodoroTotal.inMinutes,
        pomodoros: 1,
      );

      // Auto-switch to break
      _pomodoroPhase = 'short_break';
      _pomodoroTotal = const Duration(minutes: AppConstants.pomodoroBreakMinutes);
      _pomodoroRemaining = _pomodoroTotal;
      _currentSession = null;
      _phaseStart = DateTime.now();
      notifyListeners();
      _notifications.notifyStudyReminder('Break time');
    } else if (_pomodoroPhase == 'short_break') {
      _pomodoroPhase = 'work';
      _pomodoroTotal = const Duration(minutes: AppConstants.pomodoroWorkMinutes);
      _pomodoroRemaining = _pomodoroTotal;
      _currentSession = null;
      _phaseStart = DateTime.now();
      notifyListeners();
    }
  }

  Duration get elapsed =>
      _pomodoroTotal - _pomodoroRemaining;

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    super.dispose();
  }
}
