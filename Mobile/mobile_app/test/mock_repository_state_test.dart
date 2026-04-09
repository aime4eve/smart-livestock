import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/admin/data/mock_admin_repository.dart';
import 'package:smart_livestock_demo/features/alerts/data/mock_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/map/data/mock_map_repository.dart';
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

  test('Map mock repository 保留筛选条件并支持全部 ViewState', () {
    const repository = MockMapRepository();

    for (final state in ViewState.values) {
      final data = repository.load(
        viewState: state,
        selectedAnimal: 'SL-2024-002',
        selectedRange: TrajectoryRange.d7,
      );
      expect(data.viewState, state);
      expect(data.selectedAnimal, 'SL-2024-002');
      expect(data.selectedRange, TrajectoryRange.d7);
    }
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

  test('Fence mock repository 保留编辑结果', () {
    const repository = MockFenceRepository();

    for (final state in ViewState.values) {
      final data = repository.load(
        viewState: state,
        role: DemoRole.owner,
        editSaved: true,
      );
      expect(data.viewState, state);
      expect(data.editSaved, isTrue);
    }
  });

  test('Admin 与 Mine mock repository 支持全部 ViewState', () {
    const adminRepository = MockAdminRepository();
    const mineRepository = MockMineRepository();

    for (final state in ViewState.values) {
      expect(
        adminRepository.load(viewState: state, licenseAdjusted: true).viewState,
        state,
      );
      expect(mineRepository.load(state).viewState, state);
    }
  });
}
