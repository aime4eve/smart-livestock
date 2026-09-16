import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/data/device_profile_rule_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/domain/device_profile_rule_models.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/presentation/device_profile_rule_controller.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/presentation/device_profile_rules_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

DeviceProfileRule _rule(int id, String name, RuleDeviceType type, bool enabled,
        {String? remark}) =>
    DeviceProfileRule(
      id: id,
      profileName: name,
      deviceType: type,
      enabled: enabled,
      remark: remark,
      updatedAt: '2026-09-16T10:00:00Z',
    );

class _FakeRepo implements DeviceProfileRuleApiRepository {
  _FakeRepo(this._rules);

  final List<DeviceProfileRule> _rules;
  final List<Map<String, dynamic>> createdBodies = [];
  final List<int> deletedIds = [];
  bool tbReachable = true;

  @override
  Future<DeviceProfileRule> createRule(Map<String, dynamic> body) async {
    createdBodies.add(body);
    final rule = DeviceProfileRule(
      id: 100 + createdBodies.length,
      profileName: body['profileName'] as String,
      deviceType: RuleDeviceTypeX.fromApi(body['deviceType'] as String),
      enabled: body['enabled'] == true,
      remark: body['remark'] as String?,
    );
    _rules.add(rule);
    return rule;
  }

  @override
  Future<void> deleteRule(int id) async {
    deletedIds.add(id);
    _rules.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<DeviceProfileRule>> listRules() async => List.of(_rules);

  @override
  Future<List<TbProfile>> listTbProfiles() async {
    if (!tbReachable) throw Exception('TB down');
    return const [
      TbProfile(id: 'p1', name: '牛羊追踪器-OC-配置-v2'),
      TbProfile(id: 'p2', name: '瘤胃胶囊-OC-配置-v2'),
    ];
  }

  @override
  Future<DeviceProfileRule> updateRule(int id, Map<String, dynamic> body) async {
    final index = _rules.indexWhere((r) => r.id == id);
    final updated = DeviceProfileRule(
      id: id,
      profileName: _rules[index].profileName,
      deviceType: RuleDeviceTypeX.fromApi(body['deviceType'] as String),
      enabled: body['enabled'] == true,
      remark: (body['remark'] as String?) ?? _rules[index].remark,
    );
    _rules[index] = updated;
    return updated;
  }
}

Widget _buildApp(_FakeRepo repo) => ProviderScope(
      overrides: [
        deviceProfileRuleRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeviceProfileRulesPage(),
      ),
    );

void main() {
  testWidgets('renders rules with type badges, switches and disabled rows',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _FakeRepo([
      _rule(1, '牛羊追踪器-OC-配置-v2', RuleDeviceType.tracker, true,
          remark: '现行 OC 链路'),
      _rule(2, '旧链路-profile', RuleDeviceType.capsule, false),
    ]);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('牛羊追踪器-OC-配置-v2'), findsOneWidget);
    expect(find.text('旧链路-profile'), findsOneWidget);
    expect(find.text('已停用'), findsOneWidget);
    expect(find.text('共 2 条规则 · 启用 1 · 停用 1'), findsOneWidget);
    // Two switches: one on, one off.
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));
    expect(tester.widget<Switch>(switches.at(0)).value, isTrue);
    expect(tester.widget<Switch>(switches.at(1)).value, isFalse);
  });

  testWidgets('delete requires confirmation and calls the API',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _FakeRepo([
      _rule(1, '牛羊追踪器-OC-配置-v2', RuleDeviceType.tracker, true),
    ]);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    // Warning box names the profile; cancel first keeps the rule.
    expect(find.textContaining('牛羊追踪器-OC-配置-v2'), findsWidgets);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repo.deletedIds, isEmpty);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(repo.deletedIds, [1]);
    expect(find.textContaining('牛羊追踪器-OC-配置-v2'), findsNothing);
  });

  testWidgets('create form blocks duplicate names locally', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _FakeRepo([
      _rule(1, '牛羊追踪器-OC-配置-v2', RuleDeviceType.tracker, true),
    ]);
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新增规则'));
    await tester.pumpAndSettle();

    // Switch to manual input, type a duplicate name, save → local error,
    // no API call.
    await tester.tap(find.text('或 手动输入配置名 →'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '牛羊追踪器-OC-配置-v2');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('已存在同名规则'), findsOneWidget);
    expect(repo.createdBodies, isEmpty);
  });
}
