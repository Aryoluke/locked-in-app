import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/local_db_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService.instance;
  final LocalDbService _db = LocalDbService.instance;

  AuthState _state = AuthState.unknown;
  User? _user;
  bool _loading = true;
  String? _error;
  StreamSubscription? _sub;

  AuthState get state => _state;
  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get hasCompletedOnboarding => _user?.onboardingComplete ?? false;

  Future<void> init() async {
    _sub ??= _auth.stream.listen((s) {
      _state = s;
      _user = _auth.currentUser;
      notifyListeners();
    });

    await _auth.init();
    _state = _auth.state;
    _user = _auth.currentUser;

    // Load user from local DB if not in memory
    if (_user == null) {
      try {
        final rows = await _db.queryAll('users', orderBy: 'updated_at DESC', limit: 1);
        if (rows.isNotEmpty) {
          _user = User.fromMap(rows.first);
        }
      } catch (_) {}
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.login(email, password);
      _user = _auth.currentUser;
      _state = AuthState.authenticated;
      await _cacheUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll(RegExp(r'.*: '), '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String inviteCode,
    String? displayName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.signup(
        email: email,
        password: password,
        inviteCode: inviteCode,
        displayName: displayName,
      );
      _user = _auth.currentUser;
      _state = AuthState.authenticated;
      await _cacheUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll(RegExp(r'.*: '), '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _cacheUser() async {
    if (_user == null) return;
    await _db.upsert('users', _user!.toMap(), conflictTarget: 'id');
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> completeOnboarding(User updated) async {
    _user = updated;
    await _cacheUser();
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final updated = await ApiService.instance.updateUserProfile(updates);
      _user = updated;
    } catch (_) {
      // Offline: apply supported edits locally only.
      if (_user != null && updates.containsKey('display_name')) {
        _user = _user!.copyWith(
          displayName: updates['display_name'] as String?,
        );
      }
    }
    await _cacheUser();
    notifyListeners();
  }

  void setUser(User u) {
    _user = u;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
