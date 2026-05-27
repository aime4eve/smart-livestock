import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_shell.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';

class _NoFarmController extends FarmSwitcherController {
  @override
  FarmSwitcherState build() => const FarmSwitcherState(
        farms: [],
        activeFarmId: null,
        isLoading: false,
      );
}

class _OwnerSession extends SessionController {
  @override
  AppSession build() => AppSession.authenticated(
        role: UserRole.owner,
        accessToken: 'test-token',
        userId: 1,
        userName: '测试牧场主',
        phone: '13800138000',
        tenantId: 1,
        username: 'testowner',
        activeFarmId: null,
      );
}

void main() {
  testWidgets('owner 无牧场时显示联系管理员引导', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => _OwnerSession()),
        farmSwitcherControllerProvider
            .overrideWith(() => _NoFarmController()),
      ],
      child: const MaterialApp(
        home: DemoShell(
          location: '/twin',
          child: SizedBox.shrink(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('暂无关联牧场，请联系管理员为您分配牧场。'),
      findsOneWidget,
    );
    expect(
      find.text('请创建您的第一个牧场'),
      findsNothing,
    );
  });
}
