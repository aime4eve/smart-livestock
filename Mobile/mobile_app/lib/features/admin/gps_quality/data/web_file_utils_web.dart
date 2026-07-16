import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser download of [bytes] as [fileName] on Flutter web.
Future<void> downloadBytes(String fileName, List<int> bytes) async {
  final blob = html.Blob(
    [Uint8List.fromList(bytes)],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

/// Opens a native file picker via a hidden <input type="file"> element
/// and returns the selected file's bytes. Returns null on cancel.
Future<List<int>?> pickFileBytes(List<String> extensions) async {
  final input = html.InputElement(type: 'file')
    ..accept = '.${extensions.join(',.')}'
    ..style.display = 'none';
  html.document.body?.children.add(input);

  final completer = Completer<List<int>?>();

  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(result.toList());
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) => completer.complete(null));
    reader.readAsArrayBuffer(file);
  });

  // Click to open the file dialog
  input.click();

  final result = await completer.future;
  html.document.body?.children.remove(input);
  return result;
}
