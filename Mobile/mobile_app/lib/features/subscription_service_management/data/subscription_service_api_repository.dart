import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/domain/subscription_service_repository.dart';

class SubscriptionServiceApiRepository implements SubscriptionServiceRepository {
  const SubscriptionServiceApiRepository();

  @override
  Future<SubscriptionServiceListViewData> getServices({
    String? tenantId,
    String? status,
  }) async {
    final data = await ApiClient.instance.get('/admin/subscription-services');
    final items = data['items'] as List? ?? [];
    var services = items.whereType<Map<String, dynamic>>().toList();
    if (tenantId != null) {
      services = services.where((s) => s['tenantId'] == tenantId).toList();
    }
    if (status != null) {
      services = services.where((s) => s['status'] == status).toList();
    }
    return SubscriptionServiceListViewData(
      services: services,
      total: data['total'] as int? ?? services.length,
    );
  }

  @override
  Future<bool> createService(Map<String, dynamic> data) async {
    await ApiClient.instance.post('/admin/subscription-services', body: data);
    return true;
  }

  @override
  Future<bool> renewService(String serviceId, String endDate) async {
    await ApiClient.instance.put('/admin/subscription-services/$serviceId',
        body: {'endDate': endDate, 'status': 'active'});
    return true;
  }

  @override
  Future<bool> revokeService(String serviceId) async {
    await ApiClient.instance.put('/admin/subscription-services/$serviceId',
        body: {'status': 'revoked'});
    return true;
  }
}
