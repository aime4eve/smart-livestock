import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_list_page.dart';

void main() {
  testWidgets('TenantListPage 列表项渲染 mock 数据', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: TenantListPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-tenant-list')), findsOneWidget);
    expect(find.text('华东示范牧场'), findsOneWidget);
  });
}
