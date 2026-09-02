import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../config/constants.dart';
import '../models/sync.dart';
import 'api_service.dart';
import 'local_db_service.dart';

class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final ApiService _api = ApiService.instance;
  final LocalDbService _db = LocalDbService.instance;

  final StreamController<SyncState> _statusController =
      StreamController<SyncState>.broadcast();
  final StreamController<SyncSummary> _summaryController =
      StreamController<SyncSummary>.broadcast();

  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _enabled = true;

  Stream<SyncState> get statusStream => _statusController.stream;
  Stream<SyncSummary> get summaryStream => _summaryController.stream;
  SyncState status = SyncState.idle;
  int pendingCount = 0;

  // ── Client entity type → server table name ──────────────────────────
  // NOTE: 'user' removed — server discards all user push data (READONLY).
  static const Map<String, String> _entityToServerTable = {
    'workout': 'workout_sessions',
    'workout_set': 'workout_sets',
    'habit': 'habits',
    'habit_log': 'habit_logs',
    'daily_log': 'daily_logs',
    'body_log': 'body_logs',
    'sleep_log': 'sleep_logs',
    'supplement_log': 'supplement_logs',
    'study_log': 'study_logs',
    'pomodoro': 'pomodoro_sessions',
    'streak': 'streaks',
    'xp': 'xp_transactions',
  };

  // ── Server table name → local table name ────────────────────────────
  // Tables not listed here are silently skipped (no local equivalent yet).
  static const Map<String, String> _serverToLocalTable = {
    'workout_sessions': 'workouts',
    'workout_sets': 'workout_sets',
    'habits': 'habits',
    'habit_logs': 'habit_completions',
    'daily_logs': 'daily_logs',
    'body_logs': 'body_logs',
    'study_logs': 'study_logs',
    'pomodoro_sessions': 'pomodoro_sessions',
    'streaks': 'streaks',
    'xp_transactions': 'xp_transactions',
    'users': 'users',
  };

  // ── Client → Server field name mapping (for push) ───────────────────
  static const Map<String, Map<String, String>> _clientToServerFields = {
    'workout_sessions': {
      'total_volume': 'total_volume_kg',
      // Note: start_time→date, end_time→duration_minutes are COMPUTED, not just renamed
    },
    'workout_sets': {
      'weight': 'weight_kg',
      'workout_id': 'session_id',
      'timestamp': 'created_at',
    },
    'habits': {
      'target_count': 'target_frequency',
      'enabled': 'is_active',
      'sort_order': 'order_index',
    },
    'habit_logs': {
      'count': 'value',
    },
    'daily_logs': {
      'water_liters': 'water_ml',
      'energy_level': 'energy',
      'body_weight': 'weight_kg',
    },
    'body_logs': {
      'weight': 'weight_kg',
      'body_fat_percentage': 'body_fat_pct',
      'biceps': 'arm_cm',
      'chest': 'chest_cm',
      'waist': 'waist_cm',
    },
    'study_logs': {
      'minutes': 'duration_minutes',
    },
    'pomodoro_sessions': {
      'planned_minutes': 'duration_minutes',
      'tag': 'subject',
    },
    'streaks': {
      'last_completed_at': 'last_active_date',
    },
    'xp_transactions': {
      'timestamp': 'created_at',
    },
  };

  // ── Server → Client field name mapping (for pull) ───────────────────
  static const Map<String, Map<String, String>> _serverToClientFields = {
    'workout_sessions': {
      'total_volume_kg': 'total_volume',
      'created_at': 'timestamp',
    },
    'workout_sets': {
      'session_id': 'workout_id',
      'weight_kg': 'weight',
      'created_at': 'timestamp',
    },
    'habits': {
      'target_frequency': 'target_count',
      'is_active': 'enabled',
      'order_index': 'sort_order',
    },
    'habit_logs': {}, // special handling needed — see _applyPullTransforms
    'daily_logs': {
      'water_ml': 'water_liters',
      'energy': 'energy_level',
      'weight_kg': 'body_weight',
    },
    'body_logs': {
      'weight_kg': 'weight',
      'body_fat_pct': 'body_fat_percentage',
      'arm_cm': 'biceps',
      'chest_cm': 'chest',
      'waist_cm': 'waist',
    },
    'study_logs': {
      'duration_minutes': 'minutes',
    },
    'pomodoro_sessions': {
      'duration_minutes': 'planned_minutes',
      'subject': 'tag',
    },
    'streaks': {
      'last_active_date': 'last_completed_at',
    },
    'xp_transactions': {
      'created_at': 'timestamp',
    },
    'users': {
      'dob': 'date_of_birth',
      'sleep_baseline': 'sleep_schedule',
      'equipment': 'available_equipment',
    },
  };

  // ── Fields to strip on pull (server-only, no client column) ─────────
  static const Map<String, Set<String>> _serverFieldsToStrip = {
    'workout_sessions': {
      'user_id', 'workout_type', 'notes', 'is_template', 'template_name',
      'created_at', 'updated_at',
    },
    'workout_sets': {
      'exercise_variation', 'rest_seconds', 'is_warmup', 'is_dropset',
      'is_superset', 'superset_group', 'rpe', 'created_at',
    },
    'habits': {'user_id', 'color', 'target_days', 'created_at'},
    'habit_logs': {'user_id', 'completed', 'notes', 'created_at'},
    'daily_logs': {
      'user_id', 'calories', 'protein_g', 'carbs_g', 'fats_g',
      'body_fat_pct', 'xp_earned', 'created_at', 'updated_at',
    },
    'body_logs': {'user_id', 'muscle_mass_kg', 'created_at'},
    'study_logs': {'user_id', 'created_at'},
    'pomodoro_sessions': {'user_id', 'created_at'},
    'streaks': {'user_id', 'freeze_count', 'is_active', 'created_at'},
    'xp_transactions': {
      'user_id', 'source_id', 'multiplier', 'created_at',
    },
    'users': {
      'username', 'password_hash', 'invite_code_used', 'is_admin', 'age',
      'allergies', 'training_history', 'lifestyle', 'skin_type',
      'skin_concerns', 'current_routine', 'lock_in_level', 'status',
      'last_synced_at',
    },
  };

  // ── Fields to add with defaults on pull ──────────────────────────────
  static const Map<String, Map<String, dynamic>> _pullDefaults = {
    'workout_sessions': {'synced': 0},
    'workout_sets': {'exercise_id': '', 'synced': 0},
    'habits': {
      'frequency': 'daily',
      'current_streak': 0,
      'longest_streak': 0,
      'total_completions': 0,
      'synced': 0,
    },
    'habit_logs': {'synced': 0},
    'daily_logs': {'steps': 0, 'muscle_soreness': 1, 'synced': 0},
    'body_logs': {'hips': null, 'thigh': null, 'synced': 0},
    'study_logs': {'pomodoros': 0, 'focus_score': 5, 'synced': 0},
    'pomodoro_sessions': {
      'type': 'study',
      'actual_seconds': 0,
      'start_time': null,
      'end_time': null,
      'synced': 0,
    },
    'streaks': {'start_date': null, 'synced': 0},
    'xp_transactions': {'synced': 0},
    'users': {
      'fitness_goal': null,
      'onboarding_complete': 1,
      'total_xp': 0,
      'current_level': 1,
      'current_streak': 0,
      'longest_streak': 0,
      'synced': 1,
    },
  };

  // ── Fields to strip on push (client fields server doesn't have) ──────
  static const Map<String, Set<String>> _clientFieldsToStrip = {
    'workout_sessions': {'template_id', 'start_time', 'end_time', 'superset_mode'},
    'workout_sets': {'exercise_id', 'timestamp'},
    'habits': {
      'frequency', 'current_streak', 'longest_streak', 'total_completions',
    },
    'habit_logs': {}, // none to strip, but count→value transform handles it
    'daily_logs': {'steps', 'muscle_soreness'},
    'body_logs': {'hips', 'thigh'},
    'study_logs': {'pomodoros', 'focus_score'},
    'pomodoro_sessions': {
      'type', 'tag', 'actual_seconds', 'start_time', 'end_time',
    },
    'streaks': {'start_date'},
    'xp_transactions': {'is_streak_bonus'},
    'users': {
      'fitness_goal', 'onboarding_complete', 'total_xp', 'current_level',
      'current_streak', 'longest_streak',
    },
  };

  // ── Push field mapping ──────────────────────────────────────────────
  /// Renames client fields to server field names, strips client-only
  /// fields, and applies special transforms (date computation, etc.).
  Map<String, dynamic> _mapForPush(
      String serverTable, Map<String, dynamic> data) {
    // Capture values needed by transforms BEFORE stripping, since some of
    // them (start_time, end_time, is_streak_bonus) also live in the strip
    // list and would otherwise be lost before the transform can read them.
    final rawStartTime = data['start_time'];
    final rawEndTime = data['end_time'];
    final rawIsStreakBonus = data['is_streak_bonus'];

    final mapped = <String, dynamic>{};
    final rename = _clientToServerFields[serverTable];
    final strip = _clientFieldsToStrip[serverTable];

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      // Skip fields the server doesn't accept
      if (strip != null && strip.contains(key)) continue;

      // Rename if needed
      final newName = rename != null ? rename[key] : null;
      mapped[newName ?? key] = value;
    }

    // ── Push-specific transforms ────────────────────────────────────
    if (serverTable == 'workout_sessions') {
      _applyWorkoutSessionPushTransforms(
          mapped, rawStartTime, rawEndTime);
    } else if (serverTable == 'habit_logs') {
      _applyHabitLogPushTransforms(mapped);
    } else if (serverTable == 'xp_transactions') {
      _applyXpPushTransforms(mapped, rawIsStreakBonus);
    }

    return mapped;
  }

  // ── Pull field mapping ──────────────────────────────────────────────
  /// Renames server fields to client field names, strips server-only
  /// fields, applies defaults, and applies special transforms.
  Map<String, dynamic> _mapForPull(
      String serverTable, Map<String, dynamic> data) {
    // Capture values needed by transforms BEFORE stripping, since some of
    // them (e.g. habit_logs `completed`) also live in the strip list and
    // would otherwise be lost before the transform can read them.
    final rawCompleted = data['completed'];

    final mapped = <String, dynamic>{};
    final rename = _serverToClientFields[serverTable];
    final strip = _serverFieldsToStrip[serverTable];
    final defaults = _pullDefaults[serverTable];

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      // Skip fields the client doesn't store
      if (strip != null && strip.contains(key)) continue;

      // Rename if needed
      final newName = rename != null ? rename[key] : null;
      mapped[newName ?? key] = value;
    }

    // Add defaults for any missing fields
    if (defaults != null) {
      for (final entry in defaults.entries) {
        if (!mapped.containsKey(entry.key)) {
          mapped[entry.key] = entry.value;
        }
      }
    }

    // ── Pull-specific transforms ────────────────────────────────────
    if (serverTable == 'workout_sessions') {
      _applyWorkoutSessionPullTransforms(mapped);
    } else if (serverTable == 'daily_logs') {
      _applyDailyLogPullTransforms(mapped);
    } else if (serverTable == 'habit_logs') {
      _applyHabitLogPullTransforms(mapped, rawCompleted);
    }

    return mapped;
  }

  // ── Transform helpers: Push ──────────────────────────────────────────

  /// Workout sessions: compute `date` from `start_time`, compute
  /// `duration_minutes` from `start_time` and `end_time`. The raw values
  /// are passed in because start_time/end_time are stripped from the
  /// payload (they are client-only fields) but are still needed to derive
  /// the server's `date` and `duration_minutes` columns.
  void _applyWorkoutSessionPushTransforms(
      Map<String, dynamic> data, dynamic rawStartTime, dynamic rawEndTime) {
    // start_time → date (YYYY-MM-DD)
    if (rawStartTime is String && rawStartTime.isNotEmpty) {
      data['date'] =
          rawStartTime.length >= 10 ? rawStartTime.substring(0, 10) : rawStartTime;
    }

    // start_time + end_time → duration_minutes
    final start = _tryParseDateTime(rawStartTime);
    final end = _tryParseDateTime(rawEndTime);
    if (start != null && end != null) {
      data['duration_minutes'] = end.difference(start).inMinutes;
    } else if (data['duration_minutes'] == null) {
      data['duration_minutes'] = 45; // sensible default
    }
  }

  /// Habit logs: if `value` was mapped from count, also set `completed`
  /// to true when value > 0.
  void _applyHabitLogPushTransforms(Map<String, dynamic> data) {
    final value = data['value'];
    if (value is num) {
      data['completed'] = value > 0 ? true : false;
    }
  }

  /// XP transactions: convert `is_streak_bonus` (int 1/0) to
  /// `multiplier` (float 2.0 / 1.0). The raw value is passed in because
  /// is_streak_bonus is stripped from the payload (client-only field).
  void _applyXpPushTransforms(
      Map<String, dynamic> data, dynamic rawIsStreakBonus) {
    if (rawIsStreakBonus == 1 || rawIsStreakBonus == true) {
      data['multiplier'] = 2.0;
    } else {
      data['multiplier'] = 1.0;
    }
  }

  // ── Transform helpers: Pull ──────────────────────────────────────────

  /// Workout sessions: reconstruct `start_time` from `date`.
  void _applyWorkoutSessionPullTransforms(Map<String, dynamic> data) {
    final date = data['date'];
    if (date is String && date.isNotEmpty) {
      data['start_time'] = '${date}T08:00:00.000';
    }
  }

  /// Daily logs: convert `water_ml` → `water_liters` (divide by 1000).
  /// NOTE: after the server→client rename, `water_ml` is already
  /// renamed to `water_liters` by the mapping, but the value is still
  /// in millilitres — we need to convert the numeric value.
  void _applyDailyLogPullTransforms(Map<String, dynamic> data) {
    // The rename already mapped water_ml → water_liters as key,
    // but we still need to convert the value from ml to litres.
    // We detect this by checking if the renamed key exists with a numeric value.
    final waterLiters = data['water_liters'];
    if (waterLiters is num) {
      data['water_liters'] = waterLiters / 1000.0;
    }
  }

  /// Habit logs: `value` → `count` (use value if present, else 1 if
  /// completed). The raw `completed` value is passed in because it is
  /// stripped from the payload (client doesn't store `completed`) but is
  /// still useful as a fallback when `value` is absent.
  void _applyHabitLogPullTransforms(
      Map<String, dynamic> data, dynamic rawCompleted) {
    // The mapping didn't rename anything for habit_logs (empty map),
    // so the server's `value` passes through unchanged. We need `count`.
    final value = data.remove('value');
    if (value is num) {
      data['count'] = value.toInt();
    } else if (rawCompleted == true || rawCompleted == 1) {
      data['count'] = 1;
    } else {
      data['count'] = 0;
    }
  }

  /// XP transactions: `multiplier` → `is_streak_bonus` (multiplier > 1
  /// ? 1 : 0). Note: multiplier is listed in _serverFieldsToStrip, so it
  /// is removed during _mapForPull. The conversion is therefore handled
  /// inline in _applyServerChanges, where the raw multiplier is captured
  /// before stripping.

  // ── Parsing helper ──────────────────────────────────────────────────

  DateTime? _tryParseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ── Public API ──────────────────────────────────────────────────────

  Future<void> init() async {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(AppConstants.syncInterval, (_) {
      if (_enabled && !_isSyncing) {
        sync();
      }
    });
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (enabled && !_isSyncing) {
      sync();
    }
  }

  void _setStatus(SyncState s) {
    status = s;
    _statusController.add(s);
  }

  // Write-through: persist locally, queue for server
  Future<void> writeLocal(String table, String entityType, String entityId,
      Map<String, dynamic> data) async {
    await _db.upsert(table, data);
    await _queueChange(entityType, entityId, 'upsert', data);
    pendingCount = await _db.pendingCount();
    _setStatus(SyncState.hasPending);
    if (!_isSyncing && _enabled) {
      sync();
    }
  }

  // Delete through: remove locally, queue delete for server
  Future<void> deleteLocal(
      String table, String entityType, String entityId) async {
    await _db.deleteById(table, entityId);
    await _queueChange(entityType, entityId, 'delete', {});
    pendingCount = await _db.pendingCount();
    _setStatus(SyncState.hasPending);
  }

  Future<void> _queueChange(String entityType, String entityId, String op,
      Map<String, dynamic> payload) async {
    final db = await _db.database;
    await db.insert(
      'pending_changes',
      {
        'idempotency_key': '${entityType}_$entityId',
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': op,
        'payload_json': jsonEncode(payload),
        'queued_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.insert(
      'sync_status',
      {
        'entity_type': entityType,
        'entity_id': entityId,
        'status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Full sync cycle: push then pull.
  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _setStatus(SyncState.syncing);

    final summary = SyncSummary(lastSyncAt: DateTime.now());
    try {
      await _pushPending(summary);
      await _pullChanges(summary);
      await _db.setMeta(
          'last_sync', DateTime.now().toUtc().toIso8601String());
      pendingCount = await _db.pendingCount();
      summary.lastSyncAt = DateTime.now();
      _setStatus(pendingCount == 0 ? SyncState.synced : SyncState.hasPending);
      _summaryController.add(summary);
    } catch (e) {
      // ignore: avoid_print
      print('[SYNC] Error: $e');
      _setStatus(SyncState.offline);
    } finally {
      _isSyncing = false;
    }
  }

  // ── PUSH ────────────────────────────────────────────────────────────
  Future<void> _pushPending(SyncSummary summary) async {
    final db = await _db.database;
    final pendingRows =
        await db.query('pending_changes', orderBy: 'queued_at ASC');
    if (pendingRows.isEmpty) return;

    // Group pending changes by server table name to match the server's
    // SyncRecord format: {"table_name": "...", "records": [{...}]}.
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final row in pendingRows) {
      final entityType = row['entity_type'] as String;
      final serverTable = _entityToServerTable[entityType];
      if (serverTable == null) continue; // unknown type, skip

      final payload = _decodePayload(row['payload_json'] as String?);
      final mappedPayload = _mapForPush(serverTable, payload);
      final record = <String, dynamic>{
        'id': row['entity_id'],
        'data': mappedPayload,
        'timestamp': row['queued_at'],
      };
      grouped.putIfAbsent(serverTable, () => []).add(record);
    }

    if (grouped.isEmpty) return;

    // Send in chunks of 50 records total
    var index = 0;
    final allRows = pendingRows.toList();
    while (index < allRows.length) {
      final slice = allRows.skip(index).take(50).toList();
      index += 50;

      // Rebuild changes from this slice
      final sliceGrouped = <String, List<Map<String, dynamic>>>{};
      for (final row in slice) {
        final entityType = row['entity_type'] as String;
        final serverTable = _entityToServerTable[entityType];
        if (serverTable == null) continue;

        final payload = _decodePayload(row['payload_json'] as String?);
        final mappedPayload = _mapForPush(serverTable, payload);
        final record = <String, dynamic>{
          'id': row['entity_id'],
          'data': mappedPayload,
          'timestamp': row['queued_at'],
        };
        sliceGrouped.putIfAbsent(serverTable, () => []).add(record);
      }

      final sliceChanges = [
        for (final entry in sliceGrouped.entries)
          {
            'table_name': entry.key,
            'records': entry.value,
          }
      ];

      try {
        final response = await _api.syncPush(
            sliceChanges, DateTime.now().toUtc().toIso8601String());

        // Mark all as synced
        for (final row in slice) {
          await _db.markSynced(
              row['entity_type'] as String, row['entity_id'] as String);
        }
        summary.itemsPushed += slice.length;

        // Apply the server's post-push response (which includes a full pull)
        final serverChanges = response['changes'];
        if (serverChanges is List) {
          await _applyServerChanges(serverChanges, summary);
        }
      } catch (e) {
        // Mark failed records
        for (final row in slice) {
          await db.insert(
            'sync_status',
            {
              'entity_type': row['entity_type'],
              'entity_id': row['entity_id'],
              'status': 'failed',
              'updated_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        rethrow;
      }
    }
  }

  // ── PULL ────────────────────────────────────────────────────────────
  Future<void> _pullChanges(SyncSummary summary) async {
    final lastSync = await _db.getMeta('last_sync');
    final since = lastSync != null && lastSync.isNotEmpty
        ? DateTime.parse(lastSync)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final result = await _api.syncPull(since);

    // Server returns SyncResponse: {"server_timestamp", "changes": [SyncRecord...], "conflicts"}
    // Each SyncRecord is {"table_name": "...", "records": [{id, data, timestamp, ...}]}
    final serverChanges = result['changes'];
    if (serverChanges is List) {
      await _applyServerChanges(serverChanges, summary);
    }
  }

  /// Apply a list of SyncRecord groups from the server.
  /// Each element: {"table_name": "workout_sessions", "records": [{id, data, ...}]}
  Future<void> _applyServerChanges(
      List serverChanges, SyncSummary summary) async {
    for (final group in serverChanges) {
      if (group is! Map) continue;
      final serverTable = group['table_name'] as String?;
      if (serverTable == null) continue;

      final localTable = _serverToLocalTable[serverTable];
      if (localTable == null) continue; // no local table for this server table

      final records = group['records'];
      if (records is! List) continue;

      for (final rec in records) {
        if (rec is! Map) continue;
        final data = rec['data'];
        if (data is! Map) continue;

        final rawData = Map<String, dynamic>.from(data);
        final id = rec['id'] ?? rawData['id'];
        if (id == null) continue;

        // Capture raw multiplier before stripping for xp_transactions
        dynamic rawMultiplier;
        if (serverTable == 'xp_transactions') {
          rawMultiplier = rawData['multiplier'];
        }

        // Apply pull mapping: rename fields, strip server-only fields,
        // add defaults, apply transforms
        final recordData = _mapForPull(serverTable, rawData);

        // Ensure 'id' is in the data for upsert
        recordData['id'] = id;

        // XP special case: convert multiplier → is_streak_bonus
        // (done here because multiplier is stripped by _mapForPull before
        // the transform helper can see it)
        if (serverTable == 'xp_transactions') {
          if (rawMultiplier is num) {
            recordData['is_streak_bonus'] = rawMultiplier > 1 ? 1 : 0;
          } else {
            recordData['is_streak_bonus'] = 0;
          }
        }

        await _db.upsert(localTable, recordData);
        summary.itemsPulled++;
      }
    }
  }

  Map<String, dynamic> _decodePayload(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<int> refreshPendingCount() async {
    pendingCount = await _db.pendingCount();
    return pendingCount;
  }

  Future<void> dispose() {
    _syncTimer?.cancel();
    _statusController.close();
    _summaryController.close();
    return Future.value();
  }
}

enum SyncState { idle, syncing, hasPending, synced, offline }
