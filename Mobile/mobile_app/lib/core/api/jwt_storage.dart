// lib/core/api/jwt_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JwtStorage {
  JwtStorage._();
  static final JwtStorage instance = JwtStorage._();

  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
