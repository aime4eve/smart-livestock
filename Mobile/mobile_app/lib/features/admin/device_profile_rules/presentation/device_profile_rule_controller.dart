import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/data/device_profile_rule_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/domain/device_profile_rule_models.dart';

final deviceProfileRuleRepositoryProvider = Provider<DeviceProfileRuleApiRepository>(
  (_) => const DeviceProfileRuleApiRepository(),
);

/// Page data: the rule rows plus (best-effort) the live ThingsBoard profile
/// name list, used to render the 「TB」/「手动」 source chip. When TB is
/// unreachable the set stays empty and every row shows 「手动」.
class DeviceProfileRulesData {
  const DeviceProfileRulesData({
    required this.rules,
    required this.tbProfileNames,
  });

  final List<DeviceProfileRule> rules;
  final Set<String> tbProfileNames;

  bool isFromTb(String profileName) => tbProfileNames.contains(profileName);
}

class DeviceProfileRuleController extends AsyncNotifier<DeviceProfileRulesData> {
  @override
  Future<DeviceProfileRulesData> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Reload without the loading spinner; keeps old data on failure.
  Future<void> silentRefresh() async {
    final next = await AsyncValue.guard(_load);
    if (next.hasValue) state = next;
  }

  /// Flip the enabled flag inline. Reloads on success, rethrows so the page
  /// can show a snack bar, and reloads on failure to roll the switch back.
  Future<void> setEnabled(DeviceProfileRule rule, bool enabled) async {
    try {
      await ref.read(deviceProfileRuleRepositoryProvider).updateRule(rule.id, {
        'deviceType': rule.deviceType.apiName,
        'enabled': enabled,
        if (rule.remark != null) 'remark': rule.remark,
      });
      await silentRefresh();
    } catch (e) {
      await silentRefresh();
      rethrow;
    }
  }

  /// Create or update (when [ruleId] is non-null). profileName is only sent
  /// on create — the backend treats the name as immutable.
  Future<void> saveRule({
    int? ruleId,
    required String profileName,
    required RuleDeviceType deviceType,
    required bool enabled,
    String? remark,
  }) async {
    final repo = ref.read(deviceProfileRuleRepositoryProvider);
    final body = <String, dynamic>{
      'deviceType': deviceType.apiName,
      'enabled': enabled,
      'remark': remark,
    };
    if (ruleId == null) {
      body['profileName'] = profileName;
      await repo.createRule(body);
    } else {
      await repo.updateRule(ruleId, body);
    }
    await silentRefresh();
  }

  Future<void> deleteRule(int ruleId) async {
    await ref.read(deviceProfileRuleRepositoryProvider).deleteRule(ruleId);
    await silentRefresh();
  }

  Future<DeviceProfileRulesData> _load() async {
    final repo = ref.read(deviceProfileRuleRepositoryProvider);
    final rules = await repo.listRules();
    Set<String> tbNames;
    try {
      final profiles = await repo.listTbProfiles();
      tbNames = profiles.map((p) => p.name).toSet();
    } catch (_) {
      tbNames = const <String>{};
    }
    return DeviceProfileRulesData(rules: rules, tbProfileNames: tbNames);
  }
}

final deviceProfileRulesControllerProvider =
    AsyncNotifierProvider<DeviceProfileRuleController, DeviceProfileRulesData>(
  DeviceProfileRuleController.new,
);
