import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/l10n/l10n.dart';

/// Persisted locale preference (null = follow system).
final initialLocaleProvider = Provider<Locale?>((ref) => null);

class LocaleController extends Notifier<Locale?> {
  static const _prefsKey = 'app_locale';

  @override
  Locale? build() => ref.read(initialLocaleProvider);

  /// Sets the locale, persists it, and bridges to ApiClient.
  Future<void> setLocale(Locale? locale) async {
    L10n.update(locale);
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString(_prefsKey, locale.languageCode);
    } else {
      await prefs.remove(_prefsKey);
    }
    ApiClient.instance.setLocale(localeToHeader(locale));
  }

  /// Maps a Flutter [Locale] to the BCP-47 header string expected by the backend.
  static String? localeToHeader(Locale? locale) {
    if (locale == null) return null;
    switch (locale.languageCode) {
      case 'zh':
        return 'zh-CN';
      case 'en':
        return 'en';
      default:
        return locale.toLanguageTag();
    }
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
