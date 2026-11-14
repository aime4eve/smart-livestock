import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_item.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/fence_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/pages/fence_form_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-415: deep-linking straight into the edit form used to mount it
/// before the fence controller had loaded its list, and `_initForEdit`
/// latched `_initialized` on the first (empty) pass — the name stayed
/// empty forever and `_type` kept its (then-rectangle) default, so every
/// deep-linked fence showed "矩形" and a polygon fence saved through that
/// window would have persisted the wrong shape.
///
/// These tests pin the fixed sequence: stay uninitialized until the fence
/// arrives, refill via the controller subscription, and keep the polygon
/// default from leaking into the type selector.
void main() {
  final fence77Polygon = <String, dynamic>{
    'id': 77,
    'name': 'Polygon 77',
    'shape': 'polygon',
    'alarmEnabled': true,
    'active': true,
    'vertices': [
      {'lat': 28.0, 'lng': 112.0},
      {'lat': 28.01, 'lng': 112.0},
      {'lat': 28.01, 'lng': 112.01},
    ],
    'version': 3,
    'fenceType': 'sub',
  };

  final fence88Rectangle = <String, dynamic>{
    'id': 88,
    'name': 'Rect 88',
    'shape': 'rectangle',
    'alarmEnabled': true,
    'active': true,
    'vertices': [
      {'lat': 28.0, 'lng': 112.0},
      {'lat': 28.01, 'lng': 112.0},
      {'lat': 28.01, 'lng': 112.01},
      {'lat': 28.0, 'lng': 112.01},
    ],
    'version': 1,
    'fenceType': 'sub',
  };

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.setActiveFarmId('F1');
  });

  tearDown(() => ApiClient.instance.setActiveFarmId(null));

  /// GET /fences serves [fences]; other endpoints answer with empty OK so
  /// the form's map/probe calls settle.
  http.Client mockClient(List<Map<String, dynamic>> Function() fences) {
    http.Response ok(Object? data) => http.Response(
          jsonEncode({'code': 'OK', 'data': data}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
    return MockClient((req) async {
      final path = req.url.path;
      if (path.endsWith('/fences') && req.method == 'GET') {
        return ok({'items': fences()});
      }
      if (path.contains('/livestock')) return ok({'items': const []});
      return ok(const {});
    });
  }

  Widget app(String fenceId) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, __) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open-edit-form'),
                onPressed: () => context.push('/fence/form?fenceId=$fenceId'),
                child: const Text('edit'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/fence/form',
          builder: (_, state) =>
              FenceFormPage(fenceId: state.uri.queryParameters['fenceId']),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'test-token',
            activeFarmId: 'F1',
          ),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  TextEditingController nameField(WidgetTester tester) => tester
      .widget<TextFormField>(find.byType(TextFormField).first)
      .controller!;

  FenceType selectedType(WidgetTester tester) => tester
      .widget<DropdownButtonFormField<FenceType>>(
          find.byType(DropdownButtonFormField<FenceType>))
      .initialValue!;

  testWidgets(
      '深链进入编辑表单：fences 延后到达后名称与类型回填，缺省值不顶替（NIX-415）',
      (tester) async {
    var armed = false;
    await http.runWithClient(() async {
      await tester.pumpWidget(app('77'));
      await tester.pumpAndSettle();
      // Deep-link into the edit form while the controller still holds an
      // empty list (the deep-link window the fix targets); arm the data
      // only after the form has mounted.
      await tester.tap(find.byKey(const Key('open-edit-form')));
      await tester.pumpAndSettle();
      armed = true;

      // Fence not yet in the controller: the form must NOT latch the
      // (former rectangle) default as its type, and the name stays empty.
      expect(selectedType(tester), FenceType.polygon,
          reason: '缺省类型在数据未到时必须是 polygon，不得顶替显示（NIX-415 核心）');
      expect(nameField(tester).text, isEmpty);

      // Data lands → the controller subscription refills the form.
      final container =
          ProviderScope.containerOf(tester.element(find.byType(FenceFormPage)));
      container.read(fenceControllerProvider.notifier).reloadFromRepository();
      await tester.pumpAndSettle();

      expect(nameField(tester).text, 'Polygon 77');
      expect(selectedType(tester), FenceType.polygon);
      // The selector label reflects the real shape (「多边形」, not the
      // former rectangle default).
      expect(find.text('多边形'), findsWidgets);
    }, () => mockClient(() => armed ? [fence77Polygon] : const []));
  });

  testWidgets('深链进入编辑表单：rectangle 围栏数据到达后类型真回显为矩形（NIX-415）',
      (tester) async {
    var armed = false;
    await http.runWithClient(() async {
      await tester.pumpWidget(app('88'));
      await tester.pumpAndSettle();
      armed = true;
      await tester.tap(find.byKey(const Key('open-edit-form')));
      await tester.pumpAndSettle();

      final container =
          ProviderScope.containerOf(tester.element(find.byType(FenceFormPage)));
      container.read(fenceControllerProvider.notifier).reloadFromRepository();
      await tester.pumpAndSettle();

      expect(nameField(tester).text, 'Rect 88');
      expect(selectedType(tester), FenceType.rectangle);
    }, () => mockClient(() => armed ? [fence88Rectangle] : const []));
  });

  testWidgets('正常入口回归：fences 先于表单就绪时首次构建即回填', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(app('77'));
      await tester.pumpAndSettle();
      // Fence already in the controller (normal entry path).
      await tester.tap(find.byKey(const Key('open-edit-form')));
      await tester.pumpAndSettle();

      expect(nameField(tester).text, 'Polygon 77');
      expect(selectedType(tester), FenceType.polygon);
    }, () => mockClient(() => [fence77Polygon]));
  });
}
