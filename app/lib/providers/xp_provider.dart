import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/xp.dart';
import '../services/xp_service.dart';

class XpProvider extends ChangeNotifier {
  final XpService _xp = XpService.instance;
  StreamSubscription<XpAward>? _sub;

  XpAward? _lastAward;
  List<XpTransaction> _history = [];

  XpAward? get lastAward => _lastAward;
  List<XpTransaction> get history => List.unmodifiable(_history);
  int get totalXp => _xp.totalXp;
  int get level => _xp.currentLevel;
  double get progressToNext => _xp.progressToNextLevel;
  int get xpForCurrentLevel => _xp.xpForCurrentLevel;
  int get xpForNextLevel => _xp.xpForNextLevel;
  bool get justAwarded => _lastAward != null;

  Future<void> init() async {
    await _xp.init();
    _history = _xp.history;
    _sub ??= _xp.awards.listen((award) {
      _lastAward = award;
      _history = _xp.history;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<int> award({
    required int baseAmount,
    required String source,
    String? description,
    int? currentStreak,
  }) =>
      _xp.award(
        baseAmount: baseAmount,
        source: source,
        description: description,
        currentStreak: currentStreak,
      );

  void clearLastAward() {
    _lastAward = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
