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
  // Super-admin context entry (design 2026-10-19 §4.2): the root token +
  // root user info survive while a switched context session is active, so
  // exit/quick-switch needs no re-login within the token lifetime.
  static const _rootTokenKey = 'root_token';
  static const _rootUserInfoKey = 'root_user_info';
  static const _recentContextsKey = 'super_recent_contexts';

  /// Quick-switch history: last three distinct {role, tenantId, tenantName}
  /// entries, newest first (picker sheet §2.5). Cleared together with the
  /// session on logout.
  Future<void> saveRecentContexts(List<Map<String, dynamic>> recents) async {
    final raw = jsonEncode(recents);
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recentContextsKey, raw);
    } else {
      await SecureBackend.write(_recentContextsKey, raw);
    }
  }

  Future<List<Map<String, dynamic>>> getRecentContexts() async {
    final String? raw;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_recentContextsKey);
    } else {
      raw = await SecureBackend.read(_recentContextsKey);
    }
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

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

  Future<void> saveRootToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rootTokenKey, token);
    } else {
      await SecureBackend.write(_rootTokenKey, token);
    }
  }

  Future<String?> getRootToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_rootTokenKey);
    } else {
      return SecureBackend.read(_rootTokenKey);
    }
  }

  Future<void> saveRootUserInfo(Map<String, dynamic> info) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rootUserInfoKey, jsonEncode(info));
    } else {
      await SecureBackend.write(_rootUserInfoKey, jsonEncode(info));
    }
  }

  Future<Map<String, dynamic>?> getRootUserInfo() async {
    final String? raw;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_rootUserInfoKey);
    } else {
      raw = await SecureBackend.read(_rootUserInfoKey);
    }
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Drops only the root credentials (used when the root session is
  /// restored as the active one, e.g. on exit or dead context token).
  Future<void> clearRoot() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rootTokenKey);
      await prefs.remove(_rootUserInfoKey);
    } else {
      await SecureBackend.delete(_rootTokenKey);
      await SecureBackend.delete(_rootUserInfoKey);
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_userInfoKey);
      await prefs.remove(_activeFarmIdKey);
      await prefs.remove(_rootTokenKey);
      await prefs.remove(_rootUserInfoKey);
      await prefs.remove(_recentContextsKey);
    } else {
      await SecureBackend.delete(_accessTokenKey);
      await SecureBackend.delete(_userInfoKey);
      await SecureBackend.delete(_activeFarmIdKey);
      await SecureBackend.delete(_rootTokenKey);
      await SecureBackend.delete(_rootUserInfoKey);
      await SecureBackend.delete(_recentContextsKey);
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

  Future<void> deleteActiveFarmId() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeFarmIdKey);
    } else {
      await SecureBackend.delete(_activeFarmIdKey);
    }
  }
}
