// lib/features/auth/app_download_launcher.dart
//
// Triggers a browser download of an app package URL. The download row on the
// login page is only rendered when kIsWeb, so the IO stub is never invoked in
// practice; it exists so native builds still compile.
export 'app_download_launcher_io.dart'
    if (dart.library.html) 'app_download_launcher_web.dart';
