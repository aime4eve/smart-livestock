import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/b2b_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_contract_page.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_dashboard_page.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_farm_list_page.dart';

class _MockB2bRepository implements B2bRepository {
  const _MockB2bRepository();

  @override
  B2bDashboardData loadDashboard(ViewState viewState, AppMode appMode) {
    if (viewState != ViewState.normal) {
      return B2bDashboardData(viewState: viewState);
    }
    return const B2bDashboardData(
      viewState: ViewState.normal,
      totalFarms: 3,
      totalLivestock: 360,
      totalDevices: 200,
      pendingAlerts: 8,
      farms: [
        B2bFarmSummary(
          id: 'tf_001',
          name: '星辰合作牧场A',
          status: 'active',
          ownerName: '马七',
          livestockCount: 120,
          region: '华中',
        ),
        B2bFarmSummary(
          id: 'tf_002',
          name: '阳光牧场B',
          status: 'active',
          ownerName: '钱八',
          livestockCount: 150,
          region: '华东',
        ),
      ],
      contractStatus: 'active',
      contractExpiresAt: '2027-01-01T00:00:00+08:00',
    );
  }

  @override
  B2bContractData loadContract(ViewState viewState, AppMode appMode) {
    if (viewState != ViewState.normal) {
      return B2bContractData(viewState: viewState);
    }
    return const B2bContractData(
      viewState: ViewState.normal,
      id: 'contract_001',
      status: 'active',
      effectiveTier: 'standard',
      revenueShareRatio: 0.15,
      startedAt: '2026-01-01T00:00:00+08:00',
      expiresAt: '2027-01-01T00:00:00+08:00',
      signedBy: '王五',
    );
  }
}

ProviderScope _b2bTestScope(Widget child) {
  return ProviderScope(
    overrides: [
      b2bRepositoryProvider.overrideWith((_) => const _MockB2bRepository()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('B2bDashboardPage', () {
    testWidgets('显示 B端控制台标题和概览指标', (tester) async {
      await tester.pumpWidget(_b2bTestScope(const B2bDashboardPage()));
      await tester.pumpAndSettle();

      expect(find.text('B端控制台'), findsOneWidget);
      expect(find.text('旗下牧场'), findsWidgets);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('360'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('显示合同状态卡片', (tester) async {
      await tester.pumpWidget(_b2bTestScope(const B2bDashboardPage()));
      await tester.pumpAndSettle();

      expect(find.text('合同状态: active'), findsOneWidget);
      expect(find.text('到期: 2027-01-01'), findsOneWidget);
    });

    testWidgets('显示旗下 farm 列表', (tester) async {
      await tester.pumpWidget(_b2bTestScope(const B2bDashboardPage()));
      await tester.pumpAndSettle();

      expect(find.text('星辰合作牧场A'), findsOneWidget);
      expect(find.text('阳光牧场B'), findsOneWidget);
      expect(find.byKey(const Key('b2b-farm-tf_001')), findsOneWidget);
      expect(find.byKey(const Key('b2b-farm-tf_002')), findsOneWidget);
    });
  });

  group('B2bFarmListPage', () {
    testWidgets('显示旗下牧场标题和新建按钮', (tester) async {
      await tester.pumpWidget(_b2bTestScope(const B2bFarmListPage()));
      await tester.pumpAndSettle();

      expect(find.text('旗下牧场'), findsOneWidget);
      expect(find.text('新建牧场'), findsOneWidget);
      expect(find.byKey(const Key('b2b-create-farm')), findsOneWidget);
    });

    testWidgets('显示 farm 列表', (tester) async {
      await tester.pumpWidget(_b2bTestScope(const B2bFarmListPage()));
      await tester.pumpAndSettle();

      expect(find.text('星辰合作牧场A'), findsOneWidget);
      expect(
        find.text('负责人: 马七\n华中 · 牲畜: 120'),
        findsOneWidget,
      );
      expect(find.text('阳光牧场B'), findsOneWidget);
    });

    testWidgets('点击新建弹出对话框', (tester) async {
      await tester.pumpWidget(_b2bTestScope(const B2bFarmListPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('b2b-create-farm')));
      await tester.pumpAndSettle();

      expect(find.text('新建牧场'), findsWidgets);
      expect(find.byKey(const Key('b2b-farm-name-input')), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('创建'), findsOneWidget);
    });

    testWidgets('空 farm 列表时显示空状态', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            b2bDashboardControllerProvider.overrideWith(
              () => _EmptyDashboardController(),
            ),
          ],
          child: const MaterialApp(home: B2bFarmListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无旗下牧场'), findsOneWidget);
    });
  });

  group('B2bContractPage', () {
    testWidgets('显示合同信息标题', (tester) async {
      await tester.pumpWidget(_b2bTestScope(const B2bContractPage()));
      await tester.pumpAndSettle();

      expect(find.text('合同信息'), findsOneWidget);
    });

    testWidgets('显示合同详情字段', (tester) async {
      await tester.pumpWidget(_b2bTestScope(const B2bContractPage()));
      await tester.pumpAndSettle();

      expect(find.text('合同编号'), findsOneWidget);
      expect(find.text('contract_001'), findsOneWidget);
      expect(find.text('生效中'), findsOneWidget);
      expect(find.text('标准版'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('王五'), findsOneWidget);
      expect(find.text('2026-01-01'), findsOneWidget);
      expect(find.text('2027-01-01'), findsOneWidget);
    });

    testWidgets('无合同时显示空状态', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            b2bContractControllerProvider.overrideWith(
              () => _NoContractController(),
            ),
          ],
          child: const MaterialApp(home: B2bContractPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无合同信息'), findsOneWidget);
    });

    testWidgets('显示只读提示', (tester) async {
      await tester.pumpWidget(_b2bTestScope(const B2bContractPage()));
      await tester.pumpAndSettle();

      expect(
        find.text('合同为只读展示，如需变更请联系平台管理员。'),
        findsOneWidget,
      );
    });
  });
}

class _EmptyDashboardController extends B2bDashboardController {
  @override
  B2bDashboardData build() =>
      const B2bDashboardData(viewState: ViewState.normal, farms: []);
}

class _NoContractController extends B2bContractController {
  @override
  B2bContractData build() =>
      const B2bContractData(viewState: ViewState.normal);
}
