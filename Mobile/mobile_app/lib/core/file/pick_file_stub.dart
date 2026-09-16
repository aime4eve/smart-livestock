/// Stub for platforms without html/io conditional match — file picking
/// unsupported.
Future<PickedFile?> pickFileBytesWithName(List<String> extensions) async {
  throw UnsupportedError('File picking is not supported on this platform.');
}

/// Picked file with its original name (used for format detection server-side).
typedef PickedFile = ({String name, List<int> bytes});
