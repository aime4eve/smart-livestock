import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_theme.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/widgets/tb_device_wizard_sheet.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

const _eui = '001a0103ff000262';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadFonts() => Future.wait([
  _loadFont('NotoSansSC', [
    'assets/fonts/NotoSansSC-Regular.ttf',
    'assets/fonts/NotoSansSC-Medium.ttf',
    'assets/fonts/NotoSansSC-Bold.ttf',
  ]),
  _loadFont('Roboto', [
    'assets/fonts/Roboto-Regular.ttf',
    'assets/fonts/Roboto-Medium.ttf',
    'assets/fonts/Roboto-Bold.ttf',
  ]),
  _loadFont('MaterialIcons', [
    '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]),
]);

Widget _buildApp() => ProviderScope(
  overrides: [
    devicesRepositoryProvider.overrideWithValue(_FakeDevicesRepository()),
    livestockRepositoryProvider.overrideWithValue(_FakeLivestockRepository()),
    sessionControllerProvider.overrideWith(_FakeSessionController.new),
  ],
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: Key('tb-wizard-visual-boundary'),
          child: TbDeviceWizardSheet(),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('captures TB wizard confirm and result states', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tb-wizard-eui')), _eui);
    await tester.pump();
    await tester.tap(find.byKey(const Key('tb-wizard-preflight')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('tb-wizard-livestock-search')),
      '188',
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '188'), findsOneWidget);
    expect(find.text('999'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('tb-wizard-livestock-search')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '188'));
    await tester.pump();

    final sheet = find.byKey(const Key('tb-wizard-visual-boundary'));
    await expectLater(
      sheet,
      matchesGoldenFile('goldens/tb-wizard-confirm.png'),
    );

    await tester.ensureVisible(find.byKey(const Key('tb-wizard-provision')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tb-wizard-provision')));
    await tester.pumpAndSettle();
    await expectLater(sheet, matchesGoldenFile('goldens/tb-wizard-result.png'));
  });
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
      LivestockSummary(
        id: '999',
        livestockCode: '999',
        breed: Breed.angus,
        health: LivestockHealth.watch,
        fenceId: '2',
        lat: 28.2458,
        lng: 112.8519,
      ),
    ],
    total: 2,
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
      TbDevicePreflight(
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
  Future<List<Installation>> loadInstallations() async => const [];

  @override
  Future<List<GpsPoint>> loadLatestGps() async => const [];

  @override
  Future<List<GpsPoint>> loadGpsHistory(String livestockId) async => const [];

  @override
  Future<Map<String, dynamic>> loadDeviceHealth(String deviceId) async =>
      const {};
}
