// lib/core/api/api_client.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'jwt_storage.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _timeout = Duration(seconds: 15);

  String _baseUrl = kIsWeb
      ? 'http://127.0.0.1:18080/api/v1'
      : 'http://localhost:18080/api/v1';
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

  Future<Map<String, dynamic>> get(String path) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    ).timeout(_timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _handleResponse(response);
  }

  Future<void> delete(String path) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    ).timeout(_timeout);
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> farmGet(String suffix) async {
    if (_activeFarmId == null) throw StateError('No active farm');
    return get('/farms/$_activeFarmId$suffix');
  }

  Future<Map<String, dynamic>> farmPost(String suffix, {Object? body}) async {
    if (_activeFarmId == null) throw StateError('No active farm');
    return post('/farms/$_activeFarmId$suffix', body: body);
  }

  Future<Map<String, dynamic>> farmPut(String suffix, {Object? body}) async {
    if (_activeFarmId == null) throw StateError('No active farm');
    return put('/farms/$_activeFarmId$suffix', body: body);
  }

  Future<void> farmDelete(String suffix) async {
    if (_activeFarmId == null) throw StateError('No active farm');
    return delete('/farms/$_activeFarmId$suffix');
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await JwtStorage.instance.clear();
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
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
        throw ConflictException(message: message, statusCode: 409, code: code);
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
    return user;
  }

  Future<void> logout() async {
    await JwtStorage.instance.clear();
  }
}
