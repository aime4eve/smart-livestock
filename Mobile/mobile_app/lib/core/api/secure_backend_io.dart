import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Native secure storage backend (iOS/macOS/Android/Linux/Windows).
/// On web this file is never compiled — see [secure_backend_web.dart].
class SecureBackend {
  static const _storage = FlutterSecureStorage();

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);
}
