import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/domain/feature_gate_models.dart';

class FeatureGateApiRepository {
  const FeatureGateApiRepository();

  Future<List<FeatureGateEntry>> loadAll() async {
    final data = await ApiClient.instance.get('/admin/feature-gates');
    final items = (data['value'] ?? data['items'] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().map(_parse).toList();
  }

  Future<FeatureGateEntry> update(int id, {int? limitValue, int? retentionDays, bool? isEnabled}) async {
    final body = <String, dynamic>{};
    if (limitValue != null) body['limitValue'] = limitValue;
    if (retentionDays != null) body['retentionDays'] = retentionDays;
    if (isEnabled != null) body['isEnabled'] = isEnabled;
    final data = await ApiClient.instance.put('/admin/feature-gates/$id', body: body);
    return _parse(data);
  }

  FeatureGateEntry _parse(Map<String, dynamic> m) {
    return FeatureGateEntry(
      id: m['id'] as int,
      tier: (m['tier'] ?? '').toString(),
      featureKey: (m['featureKey'] ?? '').toString(),
      gateType: m['gateType']?.toString(),
      limitValue: (m['limitValue'] as num?)?.toInt() ?? 0,
      retentionDays: (m['retentionDays'] as num?)?.toInt() ?? 0,
      isEnabled: m['isEnabled'] as bool? ?? true,
    );
  }
}
