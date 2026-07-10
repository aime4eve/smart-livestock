import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/l10n/l10n.dart';

/// Persisted locale preference (null = follow system).
final initialLocaleProvider = Provider<Locale?>((ref) => null);

class LocaleController extends Notifier<Locale?> {
  static const _prefsKey = 'app_locale';

  @override
  Locale? build() => ref.read(initialLocaleProvider);

  /// Reads the persisted locale preference and applies it to [L10n] and
  /// [ApiClient] so the singleton + backend header survive a page refresh.
  /// Returns the locale to seed [initialLocaleProvider]. Call once before
  /// runApp (mirrors the session-restore flow).
  static Future<Locale?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return null;
    final locale = Locale(code);
    L10n.update(locale);
    ApiClient.instance.setLocale(localeToHeader(locale));
    return locale;
  }

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
