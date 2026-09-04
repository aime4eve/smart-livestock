import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/auth/data/deployment_info.dart';
import 'package:hkt_livestock_agentic/features/auth/login_page.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

Widget _wrap(DeploymentInfo? info) {
  return ProviderScope(
    overrides: [
      deploymentInfoProvider.overrideWith((ref) async => info),
    ],
    child: const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginPage(),
    ),
  );
}

void main() {
  testWidgets('HOSTED mode shows the cloud-hosted chip without banner',
      (tester) async {
    await tester.pumpWidget(_wrap(const DeploymentInfo(mode: 'HOSTED')));
    await tester.pumpAndSettle();

    final chip = tester.widget<HighfiStatusChip>(
      find.byKey(const Key('license-mode-chip')),
    );
    expect(chip.label, contains('云端托管'));
    expect(find.textContaining('系统未激活'), findsNothing);
  });

  testWidgets('ONPREM PENDING_ACTIVATION shows the activation banner',
      (tester) async {
    await tester.pumpWidget(_wrap(const DeploymentInfo(
      mode: 'ONPREM',
      runtimeStatus: 'PENDING_ACTIVATION',
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('license-mode-chip')), findsOneWidget);
    expect(
      find.byKey(const Key('license-mode-banner-PENDING_ACTIVATION')),
      findsOneWidget,
    );
    expect(find.textContaining('系统未激活'), findsOneWidget);
  });

  testWidgets('ONPREM EXPIRED shows the expired banner', (tester) async {
    await tester.pumpWidget(_wrap(
      const DeploymentInfo(mode: 'ONPREM', runtimeStatus: 'EXPIRED'),
    ));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('license-mode-banner-EXPIRED')),
      findsOneWidget,
    );
    expect(find.textContaining('授权已到期'), findsOneWidget);
  });

  testWidgets('deployment-info failure hides the badge and keeps the form',
      (tester) async {
    await tester.pumpWidget(_wrap(null));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('license-mode-chip')), findsNothing);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });
}
