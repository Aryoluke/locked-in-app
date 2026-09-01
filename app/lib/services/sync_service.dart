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

  Future<void> init() async {
    // Start periodic sync
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
    // Fire-and-forget immediate sync
    if (!_isSyncing && _enabled) {
      sync();
    }
  }

  // Delete through: remove locally, queue delete for server
  Future<void> deleteLocal(String table, String entityType, String entityId) async {
    await _db.deleteById(table, entityId);
    await _queueChange(entityType, entityId, 'delete', {});
    pendingCount = await _db.pendingCount();
    _setStatus(SyncState.hasPending);
  }

  Future<void> _queueChange(String entityType, String entityId, String op, Map<String, dynamic> payload) async {
    final db = await _db.database;
    await db.insert('pending_changes', {
      'idempotency_key': '${entityType}_$entityId',
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': op,
      'payload_json': jsonEncode(payload),
      'queued_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('sync_status', {
      'entity_type': entityType,
      'entity_id': entityId,
      'status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _setStatus(SyncState.syncing);

    final summary = SyncSummary(lastSyncAt: DateTime.now());
    try {
      // 1. Push pending changes
      await _pushPending(summary);
      // 2. Pull remote changes since last sync
      await _pullChanges(summary);
      // 3. Persist last sync timestamp
      await _db.setMeta('last_sync', DateTime.now().toUtc().toIso8601String());
      pendingCount = await _db.pendingCount();
      summary.lastSyncAt = DateTime.now();
      _setStatus(pendingCount == 0 ? SyncState.synced : SyncState.hasPending);
      _summaryController.add(summary);
    } catch (e) {
      _setStatus(SyncState.offline);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushPending(SyncSummary summary) async {
    final db = await _db.database;
    final pendingRows = await db.query('pending_changes', orderBy: 'queued_at ASC');
    if (pendingRows.isEmpty) return;

    // Batch in groups of 50
    var index = 0;
    while (index < pendingRows.length) {
      final slice = pendingRows.skip(index).take(50).toList();
      index += 50;

      final batchPayload = [
        for (final row in slice)
          {
            'entity_type': row['entity_type'],
            'entity_id': row['entity_id'],
            'operation': row['operation'],
            'payload': _decodePayload(row['payload_json'] as String?),
            'idempotency_key': row['idempotency_key'],
          }
      ];

      try {
        await _api.syncPush(batchPayload);
        // Mark all as synced
        for (final row in slice) {
          await _db.markSynced(
              row['entity_type'] as String, row['entity_id'] as String);
        }
        summary.itemsPushed += slice.length;
      } catch (e) {
        // Partial failure: mark failed records so they appear in status, keep queue
        for (final row in slice) {
          await db.insert('sync_status', {
            'entity_type': row['entity_type'],
            'entity_id': row['entity_id'],
            'status': 'failed',
            'updated_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        rethrow;
      }
    }
  }

  Future<void> _pullChanges(SyncSummary summary) async {
    final lastSync = await _db.getMeta('last_sync');
    final since = lastSync != null && lastSync.isNotEmpty
        ? DateTime.parse(lastSync)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final result = await _api.syncPull(since);
    final items = result['changes'];
    if (items is! List) return;

    for (final raw in items) {
      final change = ServerChange.fromJson(
          Map<String, dynamic>.from(raw as Map));
      await _applyServerChange(change);
      summary.itemsPulled++;
    }
  }

  Future<void> _applyServerChange(ServerChange change) async {
    final table = _tableForType(change.entityType);
    if (table == null) return;

    if (change.operation == 'delete') {
      await _db.deleteById(table, change.entityId);
      await _db.markSynced(change.entityType, change.entityId);
      return;
    }

    // Last-write-wins: server change replaced directly
    final upserted = _flattenChanges(change.changes, change.entityType);
    await _db.upsert(table, upserted);
    await _db.markSynced(change.entityType, change.entityId);
  }

  Map<String, dynamic> _flattenChanges(Map<String, dynamic> changes, String type) {
    // entityId is embedded in changes by the server as 'id'
    return changes;
  }

  String? _tableForType(String entityType) {
    switch (entityType) {
      case 'user':
        return 'users';
      case 'workout':
        return 'workouts';
      case 'habit':
        return 'habits';
      case 'daily_log':
        return 'daily_logs';
      case 'study_log':
        return 'study_logs';
      case 'body_log':
        return 'body_logs';
      case 'streak':
        return 'streaks';
      case 'xp':
        return 'xp_transactions';
      default:
        return null;
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
