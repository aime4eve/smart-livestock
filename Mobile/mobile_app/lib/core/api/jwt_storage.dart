// lib/core/api/jwt_storage.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'secure_backend_io.dart'
    if (dart.library.html) 'secure_backend_web.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JwtStorage {
  JwtStorage._();
  static final JwtStorage instance = JwtStorage._();

  static const _accessTokenKey = 'access_token';
  static const _userInfoKey = 'user_info';
  static const _activeFarmIdKey = 'active_farm_id';

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    } else {
      await SecureBackend.write(_accessTokenKey, token);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } else {
      return SecureBackend.read(_accessTokenKey);
    }
  }

  /// Save user info (role, userId, userName, phone, tenantId, username) for session restoration.
  Future<void> saveUserInfo(Map<String, dynamic> info) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userInfoKey, jsonEncode(info));
    } else {
      await SecureBackend.write(_userInfoKey, jsonEncode(info));
    }
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final String? raw;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_userInfoKey);
    } else {
      raw = await SecureBackend.read(_userInfoKey);
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
      await SecureBackend.delete(_accessTokenKey);
      await SecureBackend.delete(_userInfoKey);
      await SecureBackend.delete(_activeFarmIdKey);
    }
  }

  Future<void> saveActiveFarmId(String farmId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeFarmIdKey, farmId);
    } else {
      await SecureBackend.write(_activeFarmIdKey, farmId);
    }
  }

  Future<String?> getActiveFarmId() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeFarmIdKey);
    } else {
      return SecureBackend.read(_activeFarmIdKey);
    }
  }
}
