/// Web storage backend stub.
///
/// [JwtStorage] checks `kIsWeb` before calling any SecureBackend method,
/// routing web reads/writes through SharedPreferences instead. This stub
/// exists solely to exclude `flutter_secure_storage_web` (which uses the
/// WASM-incompatible `dart:html` API) from the web bundle.
class SecureBackend {
  static Future<void> write(String key, String value) =>
      throw UnsupportedError('Use SharedPreferences on web');

  static Future<String?> read(String key) =>
      throw UnsupportedError('Use SharedPreferences on web');

  static Future<void> delete(String key) =>
      throw UnsupportedError('Use SharedPreferences on web');
}
