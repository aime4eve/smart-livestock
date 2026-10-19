// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/auth/presentation/forced_password_change_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ForcedPasswordChangePage(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('weak new password surfaces the strength rule', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('forced-current')), 'OldPass123');
    await tester.enterText(find.byKey(const Key('forced-new')), 'short1');
    await tester.enterText(find.byKey(const Key('forced-confirm')), 'short1');
    await tester.tap(find.byKey(const Key('forced-submit')));
    await tester.pump();

    // 密码策略(2026-10-15)：≥8 位 + 大写/小写/数字/特殊符号
    expect(find.text('新密码至少 8 位，且须包含大写字母、小写字母、数字和特殊符号'),
        findsOneWidget);
  });

  testWidgets('mismatched confirmation surfaces the mismatch error', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('forced-current')), 'OldPass123');
    // 两侧都满足新策略，才不会先被强度校验拦下，走不到一致性检查
    await tester.enterText(find.byKey(const Key('forced-new')), 'NewPass#123');
    await tester.enterText(find.byKey(const Key('forced-confirm')), 'NewPass#456');
    await tester.tap(find.byKey(const Key('forced-submit')));
    await tester.pump();

    expect(find.text('两次输入的新密码不一致'), findsOneWidget);
  });
}
