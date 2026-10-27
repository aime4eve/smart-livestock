import 'dart:html' as html;
import 'dart:typed_data';

/// Web: save via blob anchor (this file is only compiled into the web bundle
/// via the conditional export in save_downloaded_file.dart).
Future<String> saveDownloadedFile(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
  return fileName;
}
