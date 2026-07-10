// lib/core/api/jwt_decoder.dart

import 'dart:convert';

/// Lightweight JWT payload decoder for session restoration.
/// Only decodes the payload section (no signature verification).
class JwtDecoder {
  JwtDecoder._();

  /// Decode JWT payload without signature verification.
  static Map<String, dynamic>? tryDecode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Check if the decoded payload is expired.
  /// Returns true if expired or no exp claim.
  static bool isExpired(Map<String, dynamic> payload) {
    final exp = payload['exp'];
    if (exp == null) return true;
    final expiryMs = (exp is int) ? exp * 1000 : int.tryParse(exp.toString()) ?? 0;
    return DateTime.now().millisecondsSinceEpoch > expiryMs;
  }

  /// Returns seconds until token expiry.
  /// Negative if already expired; returns 0 if no exp claim.
  static int expiresInSeconds(Map<String, dynamic> payload) {
    final exp = payload['exp'];
    if (exp == null) return 0;
    final expirySeconds = (exp is int) ? exp : int.tryParse(exp.toString()) ?? 0;
    return expirySeconds - DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}
