import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/domain/device_profile_rule_models.dart';

/// Platform-level API for the TB device profile allowlist (NIX-214).
/// Deliberately NOT farm-scoped: the allowlist is global.
class DeviceProfileRuleApiRepository {
  const DeviceProfileRuleApiRepository();

  Future<List<DeviceProfileRule>> listRules() async {
    final data = await ApiClient.instance.get('/admin/device-profile-rules');
    return _parseList(data).map(DeviceProfileRule.fromJson).toList();
  }

  Future<DeviceProfileRule> createRule(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post('/admin/device-profile-rules', body: body);
    return DeviceProfileRule.fromJson(data);
  }

  Future<DeviceProfileRule> updateRule(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.put('/admin/device-profile-rules/$id', body: body);
    return DeviceProfileRule.fromJson(data);
  }

  Future<void> deleteRule(int id) async {
    await ApiClient.instance.delete('/admin/device-profile-rules/$id');
  }

  /// Live ThingsBoard device profile list for the form dropdown.
  /// Throws a typed Api Exception (ServerException) when TB is unreachable;
  /// the form falls back to manual input in that case.
  Future<List<TbProfile>> listTbProfiles() async {
    final data =
        await ApiClient.instance.get('/admin/device-profile-rules/tb-profiles');
    return _parseList(data)
        .map((m) => TbProfile.fromJson(m))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Map<String, dynamic>> _parseList(Map<String, dynamic> data) {
    final items = (data['value'] ?? data['items'] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().toList();
  }
}
