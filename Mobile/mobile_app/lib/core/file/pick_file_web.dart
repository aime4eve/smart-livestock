import 'dart:async';
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Picked file with its original name (used for format detection server-side).
typedef PickedFile = ({String name, List<int> bytes});

/// Opens a hidden <input type="file"> and returns the selected file's name and
/// bytes. Returns null if the user cancels.
Future<PickedFile?> pickFileBytesWithName(List<String> extensions) async {
  final input = html.InputElement(type: 'file')
    ..accept = '.${extensions.join(',.')}'
    ..style.display = 'none';
  html.document.body?.children.add(input);

  final completer = Completer<PickedFile?>();

  input.onChange.listen((_) {
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
        completer.complete((name: file.name, bytes: result.toList()));
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) => completer.complete(null));
    reader.readAsArrayBuffer(file);
  });

  input.click();

  final result = await completer.future;
  html.document.body?.children.remove(input);
  return result;
}
