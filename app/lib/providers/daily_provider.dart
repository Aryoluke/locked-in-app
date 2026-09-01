import 'package:flutter/foundation.dart';

import '../models/daily_log.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../services/xp_service.dart';

class DailyProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;
  final SyncService _sync = SyncService.instance;
  final XpService _xp = XpService.instance;

  DailyLog? _today;
  List<DailyLog> _logs = [];

  DailyLog? get today => _today;
  List<DailyLog> get logs => List.unmodifiable(_logs);

  Future<void> init() async {
    await loadToday();
    await loadHistory();
  }

  Future<void> loadToday() async {
    try {
      final todayKey = _dateKey(DateTime.now());
      final rows = await _db.queryAll('daily_logs',
          where: 'date LIKE ?', whereArgs: ['$todayKey%'], orderBy: 'date DESC');
      if (rows.isNotEmpty) {
        _today = DailyLog.fromMap(rows.first);
      } else {
        _today = DailyLog();
        await _db.upsert('daily_logs', _today!.toMap());
        await _sync.writeLocal(
            'daily_logs', 'daily_log', _today!.id, _today!.toMap());
      }
    } catch (_) {
      _today = DailyLog();
    }
    notifyListeners();
  }

  Future<void> loadHistory({int limit = 30}) async {
    try {
      final rows = await _db.queryAll('daily_logs',
          orderBy: 'date DESC', limit: limit);
      _logs = rows.map((r) => DailyLog.fromMap(r)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> logWater() async {
    if (_today == null) return;
    final updated = _today!.copyWith(
        waterLiters: (_today!.waterLiters + 0.25));
    await _save(updated);
  }

  Future<void> updateWater(double liters) async {
    if (_today == null) return;
    final updated = _today!
        .copyWith(waterLiters: liters.clamp(0.0, 6.0));
    await _save(updated);
  }

  Future<void> logSteps(int steps) async {
    if (_today == null) return;
    final updated = _today!.copyWith(steps: steps);
    await _save(updated);
  }

  Future<void> logSleep(int hours, int quality) async {
    if (_today == null) return;
    final updated = _today!.copyWith(sleepHours: hours, sleepQuality: quality);
    await _save(updated);
  }

  Future<void> logMood(int energy, int mood, int motivation) async {
    if (_today == null) return;
    final updated =
        _today!.copyWith(energyLevel: energy, mood: mood, motivation: motivation);
    await _save(updated);
  }

  Future<void> logSoreness(int soreness) async {
    if (_today == null) return;
    final updated = _today!.copyWith(muscleSoreness: soreness);
    await _save(updated);
  }

  Future<void> logBodyWeight(double kg) async {
    if (_today == null) return;
    final updated = _today!.copyWith(bodyWeight: kg);
    await _save(updated);
  }

  Future<void> addNote(String note) async {
    if (_today == null) return;
    final updated = _today!.copyWith(notes: [..._today!.notes, note]);
    await _save(updated);
  }

  Future<void> _save(DailyLog log) async {
    final prevWater = _today?.waterLiters ?? 0;
    _today = log;
    await _db.upsert('daily_logs', log.toMap());
    await _sync.writeLocal('daily_logs', 'daily_log', log.id, log.toMap());

    // Award XP on crossing water goal thresholds
    if (prevWater < 3.0 && log.waterLiters >= 3.0) {
      await _xp.award(
        baseAmount: 5,
        source: 'water',
        description: 'Hit water goal',
      );
    }

    // Update history list entry
    final idx = _logs.indexWhere((l) => l.id == log.id);
    if (idx >= 0) {
      _logs[idx] = log;
    } else {
      _logs.insert(0, log);
    }
    notifyListeners();
  }

  void setTodayLocally(DailyLog log) {
    _today = log;
    notifyListeners();
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
