import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_detail_page.dart';

void main() {
  testWidgets('Stats 卡片显示统计指标', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TenantDetailPage(id: 'tenant_001'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-detail-card-stats')), findsOneWidget);
    expect(find.text('统计概览'), findsOneWidget);
  });

  testWidgets('Devices 卡片显示设备列表', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TenantDetailPage(id: 'tenant_001'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-detail-card-devices')), findsOneWidget);
  });

  testWidgets('Logs 卡片显示操作日志', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TenantDetailPage(id: 'tenant_001'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-detail-card-logs')), findsOneWidget);
  });

  testWidgets('trends 卡片在 mock 模式下显示', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TenantDetailPage(id: 'tenant_001'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-detail-card-trends')), findsOneWidget);
    expect(find.text('30 天告警趋势'), findsOneWidget);
  });

  testWidgets('不存在的租户显示错误态', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TenantDetailPage(id: 'tenant_unknown'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('无法加载'), findsOneWidget);
  });
}
