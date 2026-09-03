import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/license/domain/deployment_license_models.dart';
import 'package:hkt_livestock_agentic/features/admin/license/presentation/deployment_license_controller.dart';
import 'package:hkt_livestock_agentic/features/admin/license/presentation/deployment_license_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

import 'fake_license_repo.dart';

Future<void> _pumpPage(WidgetTester tester, FakeLicenseRepo repo) async {
  // Tall surface so the ListView builds every card (banners included)
  // without scrolling.
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deploymentLicenseRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeploymentLicensePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('DeploymentLicensePage — HOSTED mode', () {
    testWidgets('shows hosted notice card, hides onprem sections', (tester) async {
      final repo = FakeLicenseRepo(
        mode: const LicenseModeInfo(mode: 'HOSTED', pilotLicenseEnabled: true),
      );
      await _pumpPage(tester, repo);

      expect(find.byKey(const Key('page-deployment-license')), findsOneWidget);
      expect(find.byKey(const Key('hosted-mode-card')), findsOneWidget);
      expect(find.byKey(const Key('enrollment-card')), findsNothing);
      expect(find.byKey(const Key('license-status-card')), findsNothing);
      expect(find.byKey(const Key('upload-area')), findsNothing);
    });
  });

  group('DeploymentLicensePage — ONPREM mode', () {
    testWidgets('renders tenant dropdown and enrollment info', (tester) async {
      final repo = FakeLicenseRepo();
      await _pumpPage(tester, repo);

      expect(find.byKey(const Key('license-tenant-dropdown')), findsOneWidget);
      expect(find.byKey(const Key('enrollment-card')), findsOneWidget);
      expect(find.text('inst-1'), findsOneWidget);
      expect(find.text('fp-1'), findsOneWidget);
      expect(find.text('pk-1'), findsOneWidget);
      // Copy affordances for installation id / fingerprint / public key id.
      expect(find.byKey(const Key('copy-installation-id')), findsOneWidget);
      expect(find.byKey(const Key('copy-fingerprint-hash')), findsOneWidget);
      expect(find.byKey(const Key('copy-public-key-id')), findsOneWidget);
    });

    testWidgets('renders the four runtime status chips', (tester) async {
      final cases = <LicenseRuntimeStatus, String>{
        LicenseRuntimeStatus.valid: 'license-status-chip-valid',
        LicenseRuntimeStatus.pendingActivation: 'license-status-chip-pendingActivation',
        LicenseRuntimeStatus.expired: 'license-status-chip-expired',
        LicenseRuntimeStatus.suspended: 'license-status-chip-suspended',
      };
      for (final entry in cases.entries) {
        final repo = FakeLicenseRepo()
          ..current = DeploymentLicenseStatus(
            tenantId: 1,
            runtimeStatus: entry.key,
            licenseId: 'lic-1',
            expiresAt: '2027-01-01T00:00:00Z',
          );
        await _pumpPage(tester, repo);

        expect(find.byKey(const Key('license-status-card')), findsOneWidget,
            reason: 'status card missing for ${entry.key}');
        expect(find.byKey(Key(entry.value)), findsOneWidget,
            reason: 'chip missing for ${entry.key}');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('expired / suspended show renewal guidance', (tester) async {
      for (final status in [
        LicenseRuntimeStatus.expired,
        LicenseRuntimeStatus.suspended,
      ]) {
        final repo = FakeLicenseRepo()
          ..current = DeploymentLicenseStatus(
            tenantId: 1,
            runtimeStatus: status,
            protectionReason: 'clock rollback suspected',
          );
        await _pumpPage(tester, repo);

        expect(find.byKey(const Key('renewal-guidance')), findsOneWidget,
            reason: 'renewal guidance missing for $status');
        expect(find.byKey(const Key('protection-banner')), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('valid license shows no renewal guidance and renders countdown', (tester) async {
      final repo = FakeLicenseRepo()
        ..current = const DeploymentLicenseStatus(
          tenantId: 1,
          runtimeStatus: LicenseRuntimeStatus.valid,
          licenseId: 'lic-1',
          expiresAt: '2999-01-01T00:00:00Z',
          subscriptionStatus: 'TRIAL',
          subscriptionTrialEndsAt: '2999-01-01T00:00:00Z',
        );
      await _pumpPage(tester, repo);

      expect(find.byKey(const Key('renewal-guidance')), findsNothing);
      expect(find.byKey(const Key('protection-banner')), findsNothing);
      expect(find.textContaining('days remaining'), findsOneWidget);
      // Subscription mapping section rendered (subscription status field).
      expect(find.text('TRIAL'), findsOneWidget);
    });
  });
}
