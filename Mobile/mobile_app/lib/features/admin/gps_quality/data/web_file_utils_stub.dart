/// Stub for non-web platforms — file operations are not supported.
Future<void> downloadBytes(String fileName, List<int> bytes) async {
  throw UnsupportedError('File download is only supported on web.');
}

/// Opens a native file picker and returns the selected file's bytes.
/// Returns null if the user cancels.
Future<List<int>?> pickFileBytes(List<String> extensions) async {
  throw UnsupportedError('File picking is only supported on web.');
}
