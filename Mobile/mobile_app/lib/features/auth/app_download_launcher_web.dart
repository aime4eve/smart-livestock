// lib/features/auth/app_download_launcher_web.dart

import 'package:web/web.dart' as web;

/// Clicks a synthetic anchor so the browser downloads the package file
/// in place — nginx serves .apk/.ipa as download-only MIME types, so no
/// page navigation happens.
void launchAppDownload(String url) {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = '';
  anchor.click();
}
