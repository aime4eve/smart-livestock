import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/app_router.dart';
import 'package:hkt_livestock_agentic/core/l10n/locale_controller.dart';
import 'package:hkt_livestock_agentic/core/theme/app_theme.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class DemoApp extends ConsumerWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
    );
  }
}
