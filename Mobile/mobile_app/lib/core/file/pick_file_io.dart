import 'package:file_picker/file_picker.dart';

/// Picked file with its original name (used for format detection server-side).
typedef PickedFile = ({String name, List<int> bytes});

/// Opens the native file picker (mobile/desktop) and returns the selected
/// file's name and bytes. Returns null if the user cancels.
Future<PickedFile?> pickFileBytesWithName(List<String> extensions) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
    withData: true,
  );
  final file = result?.files.single;
  if (file == null) return null;
  return (name: file.name, bytes: file.bytes?.toList() ?? <int>[]);
}
