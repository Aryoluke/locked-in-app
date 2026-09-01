import 'package:uuid/uuid.dart';

enum SyncStatus { pending, synced, failed, conflict }

class SyncRecord {
  final int id;
  final String entityType; // 'workout', 'habit', 'daily_log', 'study_log', 'user'
  final String entityId;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final SyncStatus status;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String? lastError;

  SyncRecord({
    this.id = 0,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payload,
    DateTime? createdAt,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload': payload != null ? _encode(payload!) : null,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'retry_count': retryCount,
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
        'last_error': lastError,
      };

  static String _encode(Map<String, dynamic> map) {
    return map.map((k, v) => MapEntry(k, v.toString())).toString();
  }

  factory SyncRecord.fromMap(Map<String, dynamic> map) => SyncRecord(
        id: (map['id'] as int),
        entityType: map['entity_type'] as String,
        entityId: map['entity_id'] as String,
        operation: map['operation'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        status: SyncStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => SyncStatus.pending,
        ),
        retryCount: (map['retry_count'] as int?) ?? 0,
        lastAttemptAt: map['last_attempt_at'] != null
            ? DateTime.parse(map['last_attempt_at'] as String)
            : null,
        lastError: map['last_error'] as String?,
      );

  SyncRecord copyWith({
    SyncStatus? status,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? lastError,
  }) =>
      SyncRecord(
        id: id,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        createdAt: createdAt,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
        lastError: lastError ?? this.lastError,
      );
}

class PendingChange {
  final int id;
  final String idempotencyKey;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;

  PendingChange({
    this.id = 0,
    String? idempotencyKey,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    DateTime? queuedAt,
  })  : idempotencyKey = idempotencyKey ?? const Uuid().v4(),
        queuedAt = queuedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'idempotency_key': idempotencyKey,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload_json': _encodeMap(payload),
        'queued_at': queuedAt.toIso8601String(),
      };

  static String _encodeMap(Map<String, dynamic> map) {
    // Simple encoding to a JSON-ish string of key:value pairs
    final buffer = StringBuffer('{');
    map.forEach((k, v) {
      buffer.write('"$k":"$v",');
    });
    buffer.write('}');
    return buffer.toString();
  }

  factory PendingChange.fromMap(Map<String, dynamic> map) => PendingChange(
        id: (map['id'] as int),
        idempotencyKey: map['idempotency_key'] as String,
        entityType: map['entity_type'] as String,
        entityId: map['entity_id'] as String,
        operation: map['operation'] as String,
        queuedAt: DateTime.parse(map['queued_at'] as String),
        payload: _decodeMap(map['payload_json'] as String? ?? '{}'),
      );

  static Map<String, dynamic> _decodeMap(String jsonStr) {
    final result = <String, dynamic>{};
    var s = jsonStr.trim();
    if (s.length >= 2 && s.startsWith('{') && s.endsWith('}')) {
      s = s.substring(1, s.length - 1);
    }
    if (s.isEmpty) return result;
    final parts = s.split(',');
    for (final part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        result[kv[0].replaceAll('"', '').trim()] =
            kv[1].replaceAll('"', '').trim();
      }
    }
    return result;
  }
}

class ServerChange {
  final String entityType;
  final String entityId;
  final String operation;
  final DateTime changedAt;
  final Map<String, dynamic> changes;

  ServerChange({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.changedAt,
    required this.changes,
  });

  factory ServerChange.fromJson(Map<String, dynamic> json) => ServerChange(
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        operation: json['operation'] as String,
        changedAt: DateTime.parse(json['changed_at'] as String),
        changes: Map<String, dynamic>.from(json['changes'] as Map),
      );
}

class SyncSummary {
  DateTime lastSyncAt;
  int itemsPushed;
  int itemsPulled;
  int conflictsResolved;
  bool success;

  SyncSummary({
    required this.lastSyncAt,
    this.itemsPushed = 0,
    this.itemsPulled = 0,
    this.conflictsResolved = 0,
    this.success = true,
  });

  factory SyncSummary.empty() => SyncSummary(lastSyncAt: DateTime.now());
}
