import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/user.dart';

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  final http.Client _client = http.Client();
  String _baseUrl = AppConstants.defaultBaseUrl;
  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshWaiters = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(AppConstants.baseUrlKey) ?? AppConstants.defaultBaseUrl;
    _accessToken = prefs.getString(AppConstants.tokenKey);
    _refreshToken = prefs.getString(AppConstants.refreshTokenKey);
  }

  String get baseUrl => _baseUrl;

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.baseUrlKey, url);
  }

  bool get hasToken => _accessToken != null;

  void setTokens(String access, String refresh) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Uri _uri(String path) {
    var fullPath = path;
    if (!fullPath.startsWith('/')) {
      fullPath = '/$fullPath';
    }
    if (!fullPath.startsWith(AppConstants.apiVersion)) {
      fullPath = '${AppConstants.apiVersion}$fullPath';
    }
    return Uri.parse('$_baseUrl$fullPath');
  }

  Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  bool get isOffline {
    // Placeholder network-state check; actual detection via connectivity plugin.
    // We treat unreachable server as offline at throw time.
    return false;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
    bool retryOn401 = true,
  }) async {
    if (_logEnabled) {
      // ignore: avoid_print
      print('[API] $method ${_uri(path)} ${body ?? ''}');
    }

    try {
      final request = http.Request(method, _uri(path))
        ..headers.addAll(_headers(withAuth: withAuth));
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamed = await _client.send(request).timeout(AppConstants.apiTimeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401 && retryOn401 && withAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return _request(method, path, body: body, withAuth: withAuth, retryOn401: false);
        }
        throw ApiException('Unauthorized', statusCode: 401);
      }

      if (_logEnabled) {
        // ignore: avoid_print
        print('[API] ${response.statusCode} ${response.body.length} bytes');
      }

      return _decodeResponse(response);
    } on SocketException catch (e) {
      throw ApiException('No internet connection', isNetworkError: true, cause: e);
    } on TimeoutException {
      throw ApiException('Request timed out', isNetworkError: true);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', isNetworkError: true, cause: e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e', cause: e);
    }
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ApiException(_errorMessage(response), statusCode: response.statusCode);
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) {
        return body['detail'].toString();
      }
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
      if (body is Map && body['error'] != null) {
        return body['error'].toString();
      }
    } catch (_) {}
    return 'Server error (${response.statusCode})';
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null) return false;
    if (_isRefreshing) {
      final c = Completer<void>();
      _refreshWaiters.add(c);
      await c.future;
      return _accessToken != null;
    }
    _isRefreshing = true;
    try {
      final response = await _client
          .post(
        _uri(AppConstants.refreshTokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      )
          .timeout(AppConstants.apiTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _accessToken = data['access_token'] as String;
        _refreshToken = data['refresh_token'] as String? ?? _refreshToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, _accessToken!);
        await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
        return true;
      }
      clearTokens();
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
      for (final w in _refreshWaiters) {
        if (!w.isCompleted) w.complete();
      }
      _refreshWaiters.clear();
    }
  }

  // ===== Auth =====
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      withAuth: false,
    );
    final creds = data as Map<String, dynamic>;
    setTokens(creds['access_token'] as String, creds['refresh_token'] as String);
    _persistTokens();
    return creds;
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String inviteCode,
    String? displayName,
  }) async {
    final data = await _request(
      'POST',
      '/auth/signup',
      body: {
        'email': email,
        'password': password,
        'invite_code': inviteCode,
        'display_name': displayName,
      },
      withAuth: false,
    );
    final creds = data as Map<String, dynamic>;
    setTokens(creds['access_token'] as String, creds['refresh_token'] as String);
    _persistTokens();
    return creds;
  }

  Future<void> _persistTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(AppConstants.tokenKey, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
    }
  }

  Future<void> logout() async {
    clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
  }

  // ===== User =====
  Future<User> getUserProfile() async {
    final data = await _request('GET', AppConstants.profileEndpoint);
    return User.fromMap(_asStringMap(data));
  }

  Future<User> updateUserProfile(Map<String, dynamic> updates) async {
    final data = await _request('PUT', AppConstants.profileEndpoint, body: updates);
    return User.fromMap(_asStringMap(data));
  }

  // ===== Generic endpoints =====
  Future<List<Map<String, dynamic>>> getList(String endpoint) async {
    final data = await _request('GET', endpoint);
    if (data is List) {
      return data.map((e) => _asStringMap(e)).toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List).map((e) => _asStringMap(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getOne(String endpoint, String id) async {
    final data = await _request('GET', '$endpoint/$id');
    return _asStringMap(data);
  }

  Future<Map<String, dynamic>> create(String endpoint, Map<String, dynamic> body) async {
    final data = await _request('POST', endpoint, body: body);
    return _asStringMap(data);
  }

  Future<Map<String, dynamic>> update(String endpoint, String id, Map<String, dynamic> body) async {
    final data = await _request('PUT', '$endpoint/$id', body: body);
    return _asStringMap(data);
  }

  Future<Map<String, dynamic>> patch(String endpoint, String id, Map<String, dynamic> body) async {
    final data = await _request('PATCH', '$endpoint/$id', body: body);
    return _asStringMap(data);
  }

  Future<void> delete(String endpoint, String id) async {
    await _request('DELETE', '$endpoint/$id');
  }

  Future<void> deleteById(String endpoint, String id) =>
      delete(endpoint, id);

  // ===== Sync =====
  Future<List<dynamic>> syncPush(List<Map<String, dynamic>> batch) async {
    final data = await _request('POST', '${AppConstants.syncEndpoint}/push', body: {'batch': batch});
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> syncPull(DateTime since) async {
    final data = await _request(
      'POST',
      '${AppConstants.syncEndpoint}/pull',
      body: {'since': since.toUtc().toIso8601String()},
    );
    return _asStringMap(data);
  }

  Future<void> syncResolve(Map<String, dynamic> resolution) async {
    await _request('POST', '${AppConstants.syncEndpoint}/resolve', body: resolution);
  }

  // Helpers
  Map<String, dynamic> _asStringMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final out = <String, dynamic>{};
      data.forEach((k, v) {
        if (v is int || v is double || v is String || v is bool || v == null) {
          out[k] = v;
        }
      });
      return out;
    }
    return <String, dynamic>{};
  }

  static bool _logEnabled = false;
  static void setLogging(bool enabled) => _logEnabled = enabled;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;
  final Object? cause;

  ApiException(this.message, {this.statusCode, this.isNetworkError = false, this.cause});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
