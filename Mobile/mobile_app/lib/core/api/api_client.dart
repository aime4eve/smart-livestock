// lib/core/api/api_client.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'jwt_storage.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _timeout = Duration(seconds: 15);

  bool _refreshInProgress = false;
  Future<String?>? _refreshFuture;

  String _baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const env = String.fromEnvironment('API_BASE_URL');
    if (kIsWeb) {
      const defaultValue = '/api/v1';
      final raw = env.isNotEmpty ? env : defaultValue;
      // If already absolute (has scheme), use as-is
      if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
      // Resolve relative path against the page origin
      return Uri.base.origin + (raw.startsWith('/') ? raw : '/$raw');
    }
    return env.isNotEmpty ? env : 'http://localhost:18080/api/v1';
  }
  String? _activeFarmId;

  String get baseUrl => _baseUrl;
  String? get activeFarmId => _activeFarmId;

  void setBaseUrl(String url) => _baseUrl = url;
  void setActiveFarmId(String? id) => _activeFarmId = id;
  Future<String?> getStoredToken() => JwtStorage.instance.getAccessToken();

  Future<Map<String, String>> _headers() async {
    final token = await JwtStorage.instance.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Public accessor for auth headers (used by OfflineTileManager downloads).
  Future<Map<String, String>> authHeaders() => _headers();

  // ── Public CRUD methods (with auto-refresh retry) ────────────────

  Future<Map<String, dynamic>> get(String path) =>
      _withRefreshRetry(() => _doGet(path));

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _withRefreshRetry(() => _doPost(path, body: body));

  Future<Map<String, dynamic>> put(String path, {Object? body}) =>
      _withRefreshRetry(() => _doPut(path, body: body));

  Future<void> delete(String path) =>
      _withRefreshRetry(() => _doDelete(path));

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _withRefreshRetry(() => _doPatch(path, body: body));

  Future<Map<String, dynamic>> farmGet(String suffix, {String? farmId}) async {
    final id = farmId ?? _activeFarmId;
    if (id == null) throw StateError('No active farm');
    return get('/farms/$id$suffix');
  }

  Future<Map<String, dynamic>> farmPost(String suffix,
      {Object? body, String? farmId}) async {
    final id = farmId ?? _activeFarmId;
    if (id == null) throw StateError('No active farm');
    return post('/farms/$id$suffix', body: body);
  }

  Future<Map<String, dynamic>> farmPut(String suffix,
      {Object? body, String? farmId}) async {
    final id = farmId ?? _activeFarmId;
    if (id == null) throw StateError('No active farm');
    return put('/farms/$id$suffix', body: body);
  }

  Future<void> farmDelete(String suffix, {String? farmId}) async {
    final id = farmId ?? _activeFarmId;
    if (id == null) throw StateError('No active farm');
    return delete('/farms/$id$suffix');
  }

  // ── Raw HTTP methods (no retry) ──────────────────────────────────

  Future<Map<String, dynamic>> _doGet(String path) async {
    // Append cache-buster to prevent browser caching on Flutter Web.
    final bustPath = path.contains('?')
        ? '$path&_t=${DateTime.now().millisecondsSinceEpoch}'
        : '$path?_t=${DateTime.now().millisecondsSinceEpoch}';
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl$bustPath'),
      headers: headers,
    ).timeout(_timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _doPost(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _doPut(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _doPatch(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _handleResponse(response);
  }

  Future<void> _doDelete(String path) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    ).timeout(_timeout);
    await _handleResponse(response);
  }

  // ── Auto-refresh retry wrapper ───────────────────────────────────

  Future<T> _withRefreshRetry<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on AuthException catch (e) {
      if (e.statusCode == 401 && e.code == 'AUTH_INVALID_TOKEN') {
        final newToken = await _tryRefresh();
        if (newToken != null) {
          return await request();
        }
      }
      rethrow;
    }
  }

  // ── Token refresh ────────────────────────────────────────────────

  Future<String?> _tryRefresh() async {
    // Coalesce concurrent refresh attempts.
    if (_refreshInProgress) {
      return _refreshFuture;
    }
    _refreshInProgress = true;
    _refreshFuture = _doRefresh();
    try {
      return await _refreshFuture;
    } finally {
      _refreshInProgress = false;
      _refreshFuture = null;
    }
  }

  Future<String?> _doRefresh() async {
    try {
      final currentToken = await JwtStorage.instance.getAccessToken();
      if (currentToken == null) return null;

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': currentToken}),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        await JwtStorage.instance.clear();
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        await JwtStorage.instance.clear();
        return null;
      }

      final newToken = data['accessToken'] as String?;
      if (newToken == null) {
        await JwtStorage.instance.clear();
        return null;
      }

      await JwtStorage.instance.saveAccessToken(newToken);

      // Also update user info if returned.
      final user = data['user'] as Map<String, dynamic>?;
      if (user != null) {
        await JwtStorage.instance.saveUserInfo(user);
      }

      return newToken;
    } catch (_) {
      await JwtStorage.instance.clear();
      return null;
    }
  }

  // ── Response handling ────────────────────────────────────────────

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      final code = body?['code'] as String?;
      if (code == 'AUTH_INVALID_TOKEN') {
        await JwtStorage.instance.clear();
      }
      throw AuthException(
        message: body?['message'] as String? ?? '认证失败',
        statusCode: 401,
        code: body?['code'] as String?,
      );
    }

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode >= 400) {
        throw ServerException(message: '服务器异常', statusCode: response.statusCode);
      }
      return {};
    }

    final code = body['code'] as String?;
    final message = body['message'] as String? ?? '';

    if (response.statusCode >= 500) {
      throw ServerException(message: message, statusCode: response.statusCode, code: code);
    }

    switch (response.statusCode) {
      case 403:
        if (code == 'TENANT_DISABLED') {
          throw ForbiddenException(message: '租户已禁用', statusCode: 403, code: code);
        }
        if (code == 'QUOTA_EXCEEDED') {
          throw QuotaExceededException(message: message, statusCode: 403, code: code);
        }
        throw ForbiddenException(message: message, statusCode: 403, code: code);
      case 404:
        throw NotFoundException(message: message, statusCode: 404, code: code);
      case 409:
        throw ConflictException(message: message, statusCode: 409, code: code, data: body['data'] as Map<String, dynamic>?);
    }

    if (response.statusCode >= 400) {
      throw ValidationException(message: message, statusCode: response.statusCode, code: code);
    }

    if (code != 'OK') {
      throw ServerException(message: message, statusCode: response.statusCode, code: code);
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null) return {};
    return {'value': data};
  }

  // ── Login / Logout (no auto-refresh) ─────────────────────────────

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    ).timeout(_timeout);

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(
        message: body['message'] as String? ?? '登录失败',
        statusCode: response.statusCode,
        code: body['code'] as String?,
      );
    }

    final data = body['data'] as Map<String, dynamic>;
    final token = data['accessToken'] as String;
    final user = data['user'] as Map<String, dynamic>;

    await JwtStorage.instance.saveAccessToken(token);
    await JwtStorage.instance.saveUserInfo(user);
    return user;
  }

  Future<void> logout() async {
    await JwtStorage.instance.clear();
  }
 // TODO: implement locale header injection

  /// Upload a file via multipart/form-data POST.
  /// The response is parsed through the standard JSON handler.
  Future<Map<String, dynamic>> uploadFile(
      String path, List<int> bytes, String fileName) async {
    final uri = Uri.parse('$_baseUrl$path');
    final authHeaders = await _headers();
    final request = http.MultipartRequest('POST', uri);
    // Include auth headers; remove Content-Type so multipart boundary is auto-set.
    request.headers.addAll(authHeaders);
    request.headers.remove('Content-Type');
    request.files
        .add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  /// Download raw bytes from a GET endpoint (e.g. binary template download).
  /// Does NOT go through the JSON _handleResponse pipeline.
  Future<List<int>> getBytes(String path) async {
    final headers = await _headers();
    final uri = Uri.parse('$_baseUrl$path');
    final response =
        await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ServerException(
        message: 'Download failed: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return response.bodyBytes;
  }

 void setLocale(String? localeHeader) {}
}
