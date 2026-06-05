// lib/core/api/jwt_storage.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JwtStorage {
  JwtStorage._();
  static final JwtStorage instance = JwtStorage._();

  static const _accessTokenKey = 'access_token';
  static const _userInfoKey = 'user_info';
  static const _activeFarmIdKey = 'active_farm_id';

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

  /// Save user info (role, userId, userName, phone, tenantId, username) for session restoration.
  Future<void> saveUserInfo(Map<String, dynamic> info) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userInfoKey, jsonEncode(info));
    } else {
      await _secureStorage.write(key: _userInfoKey, value: jsonEncode(info));
    }
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final String? raw;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_userInfoKey);
    } else {
      raw = await _secureStorage.read(key: _userInfoKey);
    }
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_userInfoKey);
      await prefs.remove(_activeFarmIdKey);
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _userInfoKey);
      await _secureStorage.delete(key: _activeFarmIdKey);
    }
  }

  Future<void> saveActiveFarmId(String farmId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeFarmIdKey, farmId);
    } else {
      await _secureStorage.write(key: _activeFarmIdKey, value: farmId);
    }
  }

  Future<String?> getActiveFarmId() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeFarmIdKey);
    } else {
      return _secureStorage.read(key: _activeFarmIdKey);
    }
  }
}
