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
    'user': 'users',
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
      final record = <String, dynamic>{
        'id': row['entity_id'],
        'data': payload,
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
        final record = <String, dynamic>{
          'id': row['entity_id'],
          'data': payload,
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

        final recordData = Map<String, dynamic>.from(data);
        final id = rec['id'] ?? recordData['id'];
        if (id == null) continue;

        // Ensure 'id' is in the data for upsert
        recordData['id'] = id;

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
