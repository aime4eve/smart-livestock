/// Conditional import: triggers a browser file download on web, no-op on
/// other platforms.
export 'excel_download_stub.dart'
    if (dart.library.html) 'excel_download_web.dart';
