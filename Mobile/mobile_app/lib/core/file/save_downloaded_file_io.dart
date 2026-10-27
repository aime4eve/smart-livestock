import 'dart:io';
import 'dart:typed_data';

/// Native: write into the system temp dir and return the absolute path.
Future<String> saveDownloadedFile(Uint8List bytes, String fileName) async {
  final file = File('\${Directory.systemTemp.path}/\$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
