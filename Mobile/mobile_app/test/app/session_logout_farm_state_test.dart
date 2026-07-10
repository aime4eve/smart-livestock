import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/models/view_state.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_item.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_repository.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/fence_controller.dart';

/// Counts how many times FarmSwitcherController.build() runs, so we can assert
/// whether logout() invalidated the provider.
class _RebuildCountingFarmSwitcher extends FarmSwitcherController {
  static int buildCount = 0;

  @override
  FarmSwitcherState build() {
    buildCount += 1;
    return super.build();
  }
}

/// Mimics ApiClient.farmGet: throws StateError('No active farm') when no active
/// farm is set, returns fences otherwise. Reproduces the real bug condition
/// (activeFarmId == null → farmGet throws) without the un-mockable ApiClient
/// singleton.
class _ConditionalFenceRepository implements FenceRepository {
  @override
  Future<List<FenceItem>> loadAll() async {
    if (ApiClient.instance.activeFarmId == null) {
      throw StateError('No active farm');
    }
    return const [_fenceA];
  }

  @override
  Future<FenceItem> loadDetail(String fenceId) async =>
      throw UnimplementedError();

  @override
  Future<FenceItem> create(Map<String, dynamic> body) async =>
      throw UnimplementedError();

  @override
  Future<FenceItem> update(String fenceId, Map<String, dynamic> body) async =>
      throw UnimplementedError();

  @override
  Future<void> delete(String fenceId) async => throw UnimplementedError();

  @override
  Future<FenceItem> forceUpdate(String fenceId, Map<String, dynamic> body) async =>
      throw UnimplementedError();
}

const _fenceA = FenceItem(
  id: 'fence_a',
  name: 'A区',
  type: FenceType.rectangle,
  alarmEnabled: true,
  active: true,
  areaHectares: 1,
  livestockCount: 1,
  colorValue: 0xFF4C9A5F,
  points: [
    LatLng(28.0, 112.0),
    LatLng(28.0, 112.1),
    LatLng(28.1, 112.1),
    LatLng(28.1, 112.0),
  ],
);

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    _RebuildCountingFarmSwitcher.buildCount = 0;
    // ApiClient 是全局单例，activeFarmId 跨测试残留（如 logout 置 null），需重置避免污染。
    ApiClient.instance.setActiveFarmId(null);
  });

  test('logout 应 invalidate farmSwitcher，使残留牧场状态被重置', () async {
    final container = ProviderContainer(
      overrides: [
        farmSwitcherControllerProvider.overrideWith(
          () => _RebuildCountingFarmSwitcher(),
        ),
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'test-token',
            activeFarmId: '1',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 首次 read：farmSwitcher 创建（build #1）
    container.read(farmSwitcherControllerProvider);
    expect(_RebuildCountingFarmSwitcher.buildCount, 1);

    await container.read(sessionControllerProvider.notifier).logout();
    expect(container.read(sessionControllerProvider).isLoggedIn, false);

    // logout 后再 read：若 logout invalidate 了 farmSwitcher，应触发重建（build #2）
    container.read(farmSwitcherControllerProvider);
    expect(
      _RebuildCountingFarmSwitcher.buildCount,
      2,
      reason: 'logout 必须 invalidate farmSwitcherControllerProvider。'
          '否则 FarmSwitcher 残留 hasFarms=true，再次登录时 MainShell 不会触发 '
          'loadFarms，activeFarmId 不恢复，/fence 等 farm-scoped 页面永久卡 loading',
    );
  });

  test('FenceController 在 activeFarmId 恢复后应自愈，不永久卡 loading', () async {
    // initialSession 给的是 session.activeFarmId，但 ApiClient 单例不会自动跟随，
    // 需手动对齐，否则初始 loadAll 会因 ApiClient.activeFarmId==null 抛 StateError。
    ApiClient.instance.setActiveFarmId('1');
    final container = ProviderContainer(
      overrides: [
        fenceRepositoryProvider.overrideWithValue(_ConditionalFenceRepository()),
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'test-token',
            activeFarmId: '1',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 初始 activeFarmId='1' → 加载成功
    container.read(fenceControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(fenceControllerProvider).viewState, ViewState.normal);

    // logout → activeFarmId=null
    await container.read(sessionControllerProvider.notifier).logout();
    // activeFarmId 变化后需 read 触发 rebuild，await 等 _loadFencesAsync 完成
    container.read(fenceControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // activeFarmId=null 时 repo 抛 StateError → catch → error（而非无限 loading）
    expect(
      container.read(fenceControllerProvider).viewState,
      ViewState.error,
      reason: 'activeFarmId 为 null 时应进入 error（可自愈），不应静默卡在 loading',
    );

    // 模拟 login 后 activeFarmId 恢复（loadFarms 触发 updateActiveFarm）
    container.read(sessionControllerProvider.notifier).updateActiveFarm('1');
    container.read(fenceControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // 自愈：activeFarmId 变化触发 rebuild → 重新加载成功
    expect(
      container.read(fenceControllerProvider).viewState,
      ViewState.normal,
      reason: 'activeFarmId 恢复后 FenceController 必须能重新加载，回到 normal',
    );
  });

  test('farm* 的 farmId 参数不污染全局 activeFarmId（b2b 跨农场防回归）', () async {
    ApiClient.instance.setActiveFarmId('owner-farm');
    try {
      await ApiClient.instance.farmGet('/map/overview', farmId: 'b2b-target-farm');
    } catch (_) {}
    expect(
      ApiClient.instance.activeFarmId,
      'owner-farm',
      reason: 'farm* 显式 farmId 必须不污染全局，否则跨农场操作（如 b2b_worker_detail '
          '查看他人农场）会让后续 farm-scoped 请求打到错误农场',
    );
  });
}
