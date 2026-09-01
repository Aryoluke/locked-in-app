import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sync.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _sync = SyncService.instance;
  StreamSubscription<SyncState>? _statusSub;
  StreamSubscription<SyncSummary>? _summarySub;

  SyncState _status = SyncState.idle;
  SyncSummary? _lastSummary;
  int _pendingCount = 0;

  SyncState get status => _status;
  SyncSummary? get lastSummary => _lastSummary;
  bool get isSyncing => _status == SyncState.syncing;
  bool get isOffline => _status == SyncState.offline;
  int get pendingCount => _sync.pendingCount;
  int get syncingPendingCount => _pendingCount;

  Future<void> init() async {
    await _sync.init();
    _status = _sync.status;
    _statusSub ??= _sync.statusStream.listen((s) {
      _status = s;
      _pendingCount = _sync.pendingCount;
      notifyListeners();
    });
    _summarySub ??= _sync.summaryStream.listen((summary) {
      _lastSummary = summary;
      _pendingCount = _sync.pendingCount;
      notifyListeners();
    });
    _pendingCount = await _sync.refreshPendingCount();
    notifyListeners();
  }

  Future<void> syncNow() => _sync.sync();

  @override
  void dispose() {
    _statusSub?.cancel();
    _summarySub?.cancel();
    super.dispose();
  }
}
