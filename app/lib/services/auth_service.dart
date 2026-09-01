import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final ApiService _api = ApiService.instance;
  User? _currentUser;
  bool _isAuthenticated = false;
  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();

  Stream<AuthState> get stream => _stateController.stream;
  AuthState get state =>
      _isAuthenticated ? AuthState.authenticated : AuthState.unauthenticated;
  User? get currentUser => _currentUser;

  Future<void> init() async {
    await _api.init();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      _emit();
      // Try to refresh profile silently; ignore errors (offline tolerated)
      try {
        _currentUser = await _api.getUserProfile();
      } catch (_) {
        _currentUser = await _loadCachedUser();
      }
    } else {
      _isAuthenticated = false;
    }
    _emit();
  }

  Future<User?> _loadCachedUser() async {
    return null; // Profile loaded from local DB by provider in practice
  }

  Future<void> login(String email, String password) async {
    final creds = await _api.login(email, password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userIdKey, creds['user_id']?.toString() ?? '');
    _isAuthenticated = true;
    _currentUser = await _api.getUserProfile();
    _emit();
  }

  Future<void> signup({
    required String email,
    required String password,
    required String inviteCode,
    String? displayName,
  }) async {
    final creds = await _api.signup(
      email: email,
      password: password,
      inviteCode: inviteCode,
      displayName: displayName,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userIdKey, creds['user_id']?.toString() ?? '');
    _isAuthenticated = true;
    _currentUser = await _api.getUserProfile();
    _emit();
  }

  Future<void> logout() async {
    await _api.logout();
    _isAuthenticated = false;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userIdKey);
    _emit();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    _currentUser = await _api.updateUserProfile(updates);
    _emit();
  }

  Future<bool> checkInviteCode(String code) async {
    try {
      await _api.create('/auth/validate-invite', {'code': code});
      return true;
    } catch (_) {
      // Offline fallback: accept locally-built invite codes of the pattern
      return code.trim().length >= 6;
    }
  }

  void _emit() {
    _stateController.add(
      _isAuthenticated ? AuthState.authenticated : AuthState.unauthenticated,
    );
  }

  void dispose() {
    _stateController.close();
  }
}

enum AuthState { authenticated, unauthenticated, unknown }
