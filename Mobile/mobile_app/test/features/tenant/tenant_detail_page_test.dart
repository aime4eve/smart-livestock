import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_detail_page.dart';

void main() {
  testWidgets('TenantDetailPage 渲染已 seed 的租户', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: TenantDetailPage(id: 'tenant_001')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('华东示范牧场'), findsOneWidget);
    expect(find.byKey(const Key('tenant-detail-card-basic')), findsOneWidget);
    expect(find.byKey(const Key('tenant-detail-delete')), findsOneWidget);
  });

  testWidgets('TenantDetailPage 未命中时显示错误态', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: TenantDetailPage(id: 'tenant_unknown')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('无法加载'), findsOneWidget);
  });
}
