import 'dart:typed_data';

/// Default (unsupported platform) implementation of the conditional triad.
Future<String> saveDownloadedFile(Uint8List bytes, String fileName) async {
  throw UnsupportedError('saveDownloadedFile: unsupported platform');
}
