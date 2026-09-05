import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/features/admin/license/domain/deployment_license_models.dart';
import 'package:hkt_livestock_agentic/features/admin/license/presentation/deployment_license_controller.dart';
import 'package:hkt_livestock_agentic/features/admin/presentation/subscriptions_page.dart';
import 'package:hkt_livestock_agentic/features/subscription_service_management/domain/subscription_service_repository.dart';
import 'package:hkt_livestock_agentic/features/subscription_service_management/presentation/subscription_service_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeSubRepo implements SubscriptionServiceRepository {
  _FakeSubRepo();

  PilotLicenseGrant grantResult = const PilotLicenseGrant(
      tenantId: '3', status: 'TRIAL', trialEndsAt: '2027-09-03T08:00:00Z');
  Object? grantError;
  int? lastPilotTenantId;

  @override
  Future<PilotLicenseGrant> grantPilotLicense(int tenantId) async {
    lastPilotTenantId = tenantId;
    final error = grantError;
    if (error != null) throw error;
    return grantResult;
  }

  @override
  Future<SubscriptionListData> loadSubscriptions({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? tier,
  }) async =>
      const SubscriptionListData(subscriptions: [], total: 0);

  @override
  Future<SubscriptionInfo> loadSubscriptionDetail(String id) => throw UnimplementedError();

  @override
  Future<SubscriptionInfo> updateSubscriptionStatus(String id, String targetStatus) =>
      throw UnimplementedError();

  @override
  Future<SubscriptionServiceListData> loadServices({int page = 1, int pageSize = 20}) async =>
      const SubscriptionServiceListData(
        services: [
          SubscriptionServiceInfo(
            id: 's1',
            tenantId: 3,
            serviceName: 'Acme Service',
            effectiveTier: 'PREMIUM',
            status: 'ACTIVE',
          ),
        ],
        total: 1,
      );

  @override
  Future<SubscriptionServiceInfo> createService(Map<String, dynamic> body) =>
      throw UnimplementedError();

  @override
  Future<SubscriptionServiceInfo> loadServiceDetail(String id) => throw UnimplementedError();

  @override
  Future<SubscriptionServiceInfo> updateServiceStatus(String id, String targetStatus) =>
      throw UnimplementedError();

  @override
  Future<SubscriptionServiceInfo> updateServiceQuota(String id, int deviceQuota) =>
      throw UnimplementedError();
}

LicenseModeInfo _mode(String mode, bool pilotEnabled) =>
    LicenseModeInfo(mode: mode, pilotLicenseEnabled: pilotEnabled);

Future<void> _pumpSubscriptions(
  WidgetTester tester, {
  required _FakeSubRepo repo,
  required LicenseModeInfo mode,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionServiceRepositoryProvider.overrideWithValue(repo),
        licenseModeProvider.overrideWith((ref) async => mode),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SubscriptionsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('pilot license — controller', () {
    test('grantPilotLicense delegates to the repository and refreshes', () async {
      final repo = _FakeSubRepo();
      final container = ProviderContainer(
        overrides: [subscriptionServiceRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(subscriptionServiceControllerProvider.future);
      await container
          .read(subscriptionServiceControllerProvider.notifier)
          .grantPilotLicense(3);

      expect(repo.lastPilotTenantId, 3);
    });

    test('grantPilotLicense rethrows STATE_CONFLICT conflict branch', () async {
      final repo = _FakeSubRepo()
        ..grantError = const ConflictException(
          message: 'state conflict',
          statusCode: 409,
          code: 'STATE_CONFLICT',
        );
      final container = ProviderContainer(
        overrides: [subscriptionServiceRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(subscriptionServiceControllerProvider.future);
      await expectLater(
        container
            .read(subscriptionServiceControllerProvider.notifier)
            .grantPilotLicense(3),
        throwsA(isA<ConflictException>()),
      );
    });
  });

  group('pilot license — SubscriptionsPage entry', () {
    testWidgets('button visible in HOSTED mode with pilot enabled', (tester) async {
      final repo = _FakeSubRepo();
      await _pumpSubscriptions(tester, repo: repo, mode: _mode('HOSTED', true));

      expect(find.byKey(const Key('grant-pilot-license')), findsOneWidget);
      expect(find.byKey(const Key('pilot-tenant-dropdown')), findsOneWidget);
    });

    testWidgets('button hidden in ONPREM mode', (tester) async {
      final repo = _FakeSubRepo();
      await _pumpSubscriptions(tester, repo: repo, mode: _mode('ONPREM', true));

      expect(find.byKey(const Key('grant-pilot-license')), findsNothing);
    });

    testWidgets('button hidden in HOSTED mode when pilot switch disabled', (tester) async {
      final repo = _FakeSubRepo();
      await _pumpSubscriptions(tester, repo: repo, mode: _mode('HOSTED', false));

      expect(find.byKey(const Key('grant-pilot-license')), findsNothing);
    });

    testWidgets('confirm flow grants the pilot license and shows trialEndsAt', (tester) async {
      final repo = _FakeSubRepo();
      await _pumpSubscriptions(tester, repo: repo, mode: _mode('HOSTED', true));

      await tester.tap(find.byKey(const Key('grant-pilot-license')));
      await tester.pumpAndSettle();
      // Confirmation dialog appears.
      expect(find.byKey(const Key('confirm-grant-pilot')), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-grant-pilot')));
      await tester.pumpAndSettle();

      expect(repo.lastPilotTenantId, 3);
      expect(find.byKey(const Key('pilot-success-snackbar')), findsOneWidget);
      expect(find.textContaining('2027-09-03'), findsOneWidget);
    });

    testWidgets('STATE_CONFLICT renders the dedicated conflict message', (tester) async {
      final repo = _FakeSubRepo()
        ..grantError = const ConflictException(
          message: 'state conflict',
          statusCode: 409,
          code: 'STATE_CONFLICT',
        );
      await _pumpSubscriptions(tester, repo: repo, mode: _mode('HOSTED', true));

      await tester.tap(find.byKey(const Key('grant-pilot-license')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-grant-pilot')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pilot-conflict-snackbar')), findsOneWidget);
    });
  });
}
