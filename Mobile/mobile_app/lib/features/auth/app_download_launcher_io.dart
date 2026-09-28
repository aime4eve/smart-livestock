// lib/features/auth/app_download_launcher_io.dart

/// No-op on native platforms: the app is already installed, so the login
/// page never renders download links outside Flutter Web.
void launchAppDownload(String url) {}
