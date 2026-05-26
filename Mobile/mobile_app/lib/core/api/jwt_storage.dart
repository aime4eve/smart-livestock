// lib/core/api/jwt_storage.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JwtStorage {
  JwtStorage._();
  static final JwtStorage instance = JwtStorage._();

  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: token);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } else {
      return _secureStorage.read(key: _accessTokenKey);
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
    }
  }
}
