import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/auth/presentation/acting_as_banner.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

void main() {
  // Widget tests have no secure-storage plugin: unregistered platform
  // channels would leave reads forever pending. Mock the channel so
  // root-token reads resolve (as null — "expired/absent root").
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel,
            (call) async => null);
  });

  testWidgets('普通会话不渲染横幅（挂载透明）', (tester) async {
    await _pump(tester, impersonated: false);
    expect(find.byKey(const Key('acting-as-banner')), findsNothing);
    expect(find.text('内容区'), findsOneWidget);
  });

  testWidgets('OWNER 上下文渲染双行横幅（含审计副行与租户名）', (tester) async {
    await _pump(tester, impersonated: true);
    expect(find.byKey(const Key('acting-as-banner')), findsOneWidget);
    expect(find.byKey(const Key('acting-as-switch')), findsOneWidget);
    expect(find.byKey(const Key('acting-as-exit')), findsOneWidget);
    expect(find.textContaining('超管代登'), findsOneWidget);
    expect(find.textContaining('南非-市场'), findsOneWidget);
    expect(find.textContaining('牧场主'), findsOneWidget);
    expect(find.textContaining('审计日志'), findsOneWidget);
  });

  testWidgets('平台上下文横幅不显示租户名', (tester) async {
    await _pump(tester,
        impersonated: true, role: UserRole.platformAdmin, tenantName: null);
    expect(find.byKey(const Key('acting-as-banner')), findsOneWidget);
    expect(find.textContaining('平台管理员'), findsOneWidget);
    expect(find.textContaining('南非-市场'), findsNothing);
  });

  testWidgets('根 token 过期时切换按钮提示重登（不弹 sheet）', (tester) async {
    await _pump(tester, impersonated: true);
    await tester.tap(find.byKey(const Key('acting-as-switch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quick-switch-sheet')), findsNothing);
    expect(find.textContaining('免密切换已过期'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required bool impersonated,
  UserRole role = UserRole.owner,
  String? tenantName = '南非-市场',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(
            () => _ContextSession(impersonated, role, tenantName)),
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
        home: Scaffold(
          body: SuperContextBannerScope(
            dense: false,
            child: Center(child: Text('内容区')),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ContextSession extends SessionController {
  final bool _impersonated;
  final UserRole _role;
  final String? _tenantName;
  _ContextSession(this._impersonated, this._role, this._tenantName);
  @override
  AppSession build() => AppSession.authenticated(
        role: _role,
        accessToken: 'ctx-token',
        userId: 6,
        tenantId: 2,
        impersonated: _impersonated,
        impersonatedTenantName: _tenantName,
      );
}
