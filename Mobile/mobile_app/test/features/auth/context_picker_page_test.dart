import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/auth/context_picker_controller.dart';
import 'package:hkt_livestock_agentic/features/auth/presentation/context_picker_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('四张角色卡与登录者卡渲染', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('super-who-card')), findsOneWidget);
    expect(find.byKey(const Key('super-role-PLATFORM_ADMIN')), findsOneWidget);
    expect(find.byKey(const Key('super-role-B2B_ADMIN')), findsOneWidget);
    expect(find.byKey(const Key('super-role-OWNER')), findsOneWidget);
    expect(find.byKey(const Key('super-role-WORKER')), findsOneWidget);
    expect(find.text('南非-市场'), findsNothing);
  });

  testWidgets('平台级角色直接弹确认 sheet', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('super-role-PLATFORM_ADMIN')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('super-confirm-sheet')), findsOneWidget);
    expect(find.text('确认进入身份'), findsOneWidget);
    expect(find.text('平台管理员'), findsWidgets);
    // 平台身份不涉及租户，无停用警示
    expect(find.byKey(const Key('super-confirm-enter')), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('super-confirm-sheet')), findsNothing);
  });

  testWidgets('租户型角色进入租户列表，三种租户状态齐全', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('super-role-OWNER')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('super-tenant-search')), findsOneWidget);
    expect(find.byKey(const Key('super-tenant-2')), findsOneWidget);
    expect(find.byKey(const Key('super-tenant-3')), findsOneWidget);
    expect(find.byKey(const Key('super-tenant-4')), findsOneWidget);
    expect(find.text('正常'), findsOneWidget);
    expect(find.text('已停用'), findsOneWidget);
    expect(find.text('试点已到期'), findsOneWidget);
    expect(find.textContaining('排障可进入'), findsOneWidget);
  });

  testWidgets('到期租户不可点击，无确认 sheet', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('super-role-OWNER')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('super-tenant-4')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('super-confirm-sheet')), findsNothing);
  });

  testWidgets('停用租户确认 sheet 带警示与「仍要进入」', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('super-role-OWNER')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('super-tenant-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('super-confirm-sheet')), findsOneWidget);
    expect(find.byKey(const Key('super-confirm-enter')), findsOneWidget);
    expect(find.text('仍要进入'), findsOneWidget);
    expect(
        find.textContaining('该租户已停用'), findsOneWidget);
    expect(find.textContaining('审计日志'), findsOneWidget);
  });

  testWidgets('正常租户确认 sheet 主按钮为「进入」', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('super-role-OWNER')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('super-tenant-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('super-confirm-sheet')), findsOneWidget);
    expect(find.text('进入'), findsOneWidget);
    expect(find.text('仍要进入'), findsNothing);
  });

  testWidgets('租户名搜索过滤列表', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('super-role-OWNER')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('super-tenant-search')), '南非');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('super-tenant-2')), findsOneWidget);
    expect(find.byKey(const Key('super-tenant-3')), findsNothing);
    expect(find.byKey(const Key('super-tenant-4')), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => _RootSession()),
        contextPickerControllerProvider.overrideWith(
            () => _PresetPickerController(_presetState())),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ContextPickerPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ContextPickerState _presetState() {
  return const ContextPickerState(
    roles: [
      EntryRoleOption(role: 'PLATFORM_ADMIN', tenantScoped: false),
      EntryRoleOption(role: 'B2B_ADMIN', tenantScoped: true),
      EntryRoleOption(role: 'OWNER', tenantScoped: true),
      EntryRoleOption(role: 'WORKER', tenantScoped: true),
    ],
    tenants: [
      TenantOption(
          id: 2,
          name: '南非-市场',
          status: 'active',
          phase: 'SAMPLE',
          timezone: 'Africa/Johannesburg',
          farmCount: 3,
          trialExpired: false),
      TenantOption(
          id: 3,
          name: 'Demo Ranch',
          status: 'disabled',
          phase: 'BATCH',
          timezone: 'Asia/Shanghai',
          farmCount: 1,
          trialExpired: false),
      TenantOption(
          id: 4,
          name: '压测租户',
          status: 'active',
          phase: 'BATCH',
          timezone: null,
          farmCount: 2,
          trialExpired: true),
    ],
  );
}
class _RootSession extends SessionController {
  @override
  AppSession build() => const AppSession.authenticated(
        role: UserRole.superAdmin,
        accessToken: 'root-token',
        userId: 6,
        userName: '超级管理员',
        username: 'Admin@hkt.com',
      );
}

class _PresetPickerController extends ContextPickerController {
  final ContextPickerState _preset;
  _PresetPickerController(this._preset);
  @override
  ContextPickerState build() => _preset;
}
