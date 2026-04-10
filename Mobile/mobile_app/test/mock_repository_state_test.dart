import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/admin/data/mock_admin_repository.dart';
import 'package:smart_livestock_demo/features/alerts/data/mock_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/mine/data/mock_mine_repository.dart';

void main() {
  test('Dashboard mock repository 支持全部 ViewState', () {
    const repository = MockDashboardRepository();

    for (final state in ViewState.values) {
      final data = repository.load(state);
      expect(data.viewState, state);
      expect(data.metrics, isNotEmpty);
    }
  });

  test('Fence mock repository 返回包含牲畜统计的围栏列表', () {
    const repository = MockFenceRepository();
    final fences = repository.loadAll();

    expect(fences.length, 4);
    expect(fences[0].name, '放牧A区');
    expect(fences[0].livestockCount, 25);
    expect(fences[1].name, '放牧B区');
    expect(fences[1].livestockCount, 18);
    expect(fences[2].name, '夜间休息区');
    expect(fences[2].livestockCount, 4);
    expect(fences[3].name, '隔离区');
    expect(fences[3].livestockCount, 3);
  });

  test('Alerts mock repository 保留角色与阶段', () {
    const repository = MockAlertsRepository();

    for (final state in ViewState.values) {
      final data = repository.load(
        viewState: state,
        role: DemoRole.owner,
        stage: AlertStage.handled,
      );
      expect(data.viewState, state);
      expect(data.role, DemoRole.owner);
      expect(data.stage, AlertStage.handled);
    }
  });

  test('Admin 与 Mine mock repository 支持全部 ViewState', () {
    const adminRepository = MockAdminRepository();
    const mineRepository = MockMineRepository();

    for (final state in ViewState.values) {
      expect(
        adminRepository
            .load(viewState: state, licenseAdjusted: true)
            .viewState,
        state,
      );
      expect(mineRepository.load(state).viewState, state);
    }
  });
}
