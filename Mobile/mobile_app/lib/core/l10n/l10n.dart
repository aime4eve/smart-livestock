import 'package:flutter/widgets.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/gen/app_localizations_en.dart';
import '../../l10n/gen/app_localizations_zh.dart';

/// Global access to the current [AppLocalizations] for code paths
/// that lack a [BuildContext] (e.g. [ApiClient] error fallbacks).
class L10n {
  L10n._();

  static AppLocalizations _instance = AppLocalizationsZh();

  static AppLocalizations get instance => _instance;

  /// Switch the active localization instance for the given locale.
  static void update(Locale? locale) {
    if (locale?.languageCode == 'en') {
      _instance = AppLocalizationsEn();
    } else {
      _instance = AppLocalizationsZh();
    }
  }
}
