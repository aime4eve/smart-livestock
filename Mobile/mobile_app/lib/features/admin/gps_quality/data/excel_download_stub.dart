/// Stub for non-web platforms — download is not supported.
Future<void> downloadBytes(String fileName, List<int> bytes) async {
  throw UnsupportedError('File download is only supported on web.');
}
