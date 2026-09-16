import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';
import 'package:hkt_livestock_agentic/features/pages/devices_page.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

const _eui = '00956906001264be';

Widget _buildApp() => ProviderScope(
  overrides: [
    devicesRepositoryProvider.overrideWithValue(_FakeDevicesRepository()),
    livestockRepositoryProvider.overrideWithValue(_FakeLivestockRepository()),
    sessionControllerProvider.overrideWith(_FakeSessionController.new),
  ],
  child: const MaterialApp(
    locale: Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: DevicesPage(),
  ),
);

void main() {
  testWidgets(
    'reopening the wizard after a successful provision starts from the input step',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // First wizard run: preflight -> provision -> result.
      await tester.tap(find.byKey(const Key('device-add-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tb-wizard-eui')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('tb-wizard-eui')), _eui);
      await tester.pump();
      await tester.tap(find.byKey(const Key('tb-wizard-preflight')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('tb-wizard-provision')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tb-wizard-provision')));
      await tester.pumpAndSettle();
      expect(find.text('153'), findsOneWidget);

      // Close via the result step's confirm button.
      final confirmButton = find.byType(FilledButton);
      await tester.ensureVisible(confirmButton);
      await tester.pumpAndSettle();
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      expect(find.text('153'), findsNothing);

      // Second run must land on the input step, not the stale result.
      await tester.tap(find.byKey(const Key('device-add-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tb-wizard-eui')), findsOneWidget);
      expect(find.text('153'), findsNothing);
    },
  );

  testWidgets(
    'the confirm step offers a back button returning to the input step',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('device-add-btn')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('tb-wizard-eui')), _eui);
      await tester.pump();
      await tester.tap(find.byKey(const Key('tb-wizard-preflight')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tb-wizard-code')), findsOneWidget);

      // Back keeps the entered EUI for editing or re-scanning.
      await tester.ensureVisible(find.byKey(const Key('tb-wizard-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tb-wizard-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tb-wizard-eui')), findsOneWidget);
      expect(find.text(_eui), findsOneWidget);
      expect(find.byKey(const Key('tb-wizard-code')), findsNothing);
    },
  );

  testWidgets(
    'the result step offers provisioning another device from a clean input',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('device-add-btn')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('tb-wizard-eui')), _eui);
      await tester.pump();
      await tester.tap(find.byKey(const Key('tb-wizard-preflight')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('tb-wizard-provision')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tb-wizard-provision')));
      await tester.pumpAndSettle();
      expect(find.text('153'), findsOneWidget);

      // Restart lands on the input step with cleared fields.
      await tester.ensureVisible(find.byKey(const Key('tb-wizard-another')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tb-wizard-another')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tb-wizard-eui')), findsOneWidget);
      expect(find.text(_eui), findsNothing);
      expect(find.text('153'), findsNothing);

      // The reset must not break the next preflight run.
      await tester.enterText(find.byKey(const Key('tb-wizard-eui')), _eui);
      await tester.pump();
      await tester.tap(find.byKey(const Key('tb-wizard-preflight')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tb-wizard-code')), findsOneWidget);
    },
  );

  testWidgets(
    'the wizard title row offers a close button that dismisses the sheet',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('device-add-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tb-wizard-close')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tb-wizard-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tb-wizard-eui')), findsNothing);
      expect(find.text('153'), findsNothing);
    },
  );
}

class _FakeSessionController extends SessionController {
  @override
  AppSession build() => const AppSession.authenticated(
    role: UserRole.owner,
    accessToken: 'test-token',
    userId: 1,
    userName: 'Test User',
    phone: '13800138000',
    tenantId: 1,
    username: 'testuser',
    activeFarmId: '1',
  );
}

class _FakeLivestockRepository implements LivestockRepository {
  @override
  Future<LivestockListData> loadAll({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? keyword,
  }) async => LivestockListData(
    items: const [
      LivestockSummary(
        id: '188',
        livestockCode: '188',
        breed: Breed.other,
        health: LivestockHealth.healthy,
        fenceId: '1',
      ),
    ],
    total: 1,
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<LivestockDetail> loadDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<LivestockDetail> create(Map<String, dynamic> body) async =>
      throw UnimplementedError();

  @override
  Future<LivestockDetail> update(String id, Map<String, dynamic> body) async =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) async {}
}

class _FakeDevicesRepository implements DevicesRepository {
  static const _candidate = TbDeviceCandidate(
    tbDeviceId: 'f80c52a0-a295-11f1-8ac2-9b57e1be74c1',
    tbDeviceName: _eui,
    profileId: 'a687f540-3334-11f1-8ac2-9b57e1be74c1',
    profileName: '瘤胃胶囊-OC-配置-v2',
    deviceType: 'CAPSULE',
    profileValid: true,
  );

  @override
  Future<TbDevicePreflight> preflightTbDevice(String eui) async =>
      const TbDevicePreflight(
        eui: _eui,
        status: 'READY_TO_INGEST',
        nsProjectId: 89,
        nsAppId: 18,
        candidates: [_candidate],
        latestTelemetryAt: '2026-08-29 09:31',
        localDeviceId: null,
        localDeviceCode: null,
        bindingStatus: null,
        activeInstallation: false,
        activeInstallationLivestockId: null,
      );

  @override
  Future<TbDeviceProvisionResult> provisionTbDevice({
    required String eui,
    String? deviceCode,
    String? deviceType,
    String? livestockId,
  }) async => TbDeviceProvisionResult(
    eui: _eui,
    localDeviceId: '153',
    deviceCode: deviceCode ?? '',
    deviceStatus: 'ACTIVE',
    bindingStatus: 'RESOLVED',
    livestockId: livestockId,
    installationCreated: livestockId != null,
    deviceType: 'CAPSULE',
    firstTelemetryTrigger: 'TB_TRIGGERED',
  );

  @override
  Future<DevicesListData> loadDevices({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  bool? unboundOnly,
  }) async => DevicesListData(
    items: const [],
    total: 0,
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<DeviceItem> loadDetail(String id) async => throw UnimplementedError();

  @override
  Future<DeviceItem> create(Map<String, dynamic> body) async =>
      throw UnimplementedError();

  @override
  Future<DeviceItem> update(String id, Map<String, dynamic> body) async =>
      throw UnimplementedError();

  @override
  Future<void> activate(String id) async {}

  @override
  Future<void> decommission(String id) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<DeviceLicense>> loadLicenses() async => const [];

  @override
  Future<List<Installation>> loadInstallations({int? pageSize, String? livestockId}) async => const [];

  @override
  Future<void> uninstall(String installationId) async {}

  @override
  Future<List<GpsPoint>> loadLatestGps() async => const [];

  @override
  Future<List<GpsPoint>> loadGpsHistory(String livestockId) async => const [];

  @override
  Future<Map<String, dynamic>> loadDeviceHealth(String deviceId) async =>
      const {};
}
