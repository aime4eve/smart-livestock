import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/domain/subscription_service_repository.dart';

class SubscriptionServiceApiRepository
    implements SubscriptionServiceRepository {
  const SubscriptionServiceApiRepository();

  // ── Subscriptions (AdminSubscriptionController) ───────────────────

  @override
  Future<SubscriptionListData> loadSubscriptions({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? tier,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (status != null) 'status': status,
      if (tier != null) 'tier': tier,
    };
    final query = Uri(queryParameters: params).query;
    final data =
        await ApiClient.instance.get('/admin/subscriptions?$query');
    final items = data['items'] as List<dynamic>? ?? [];
    final subscriptions = items
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionInfo.fromJson)
        .toList();
    return SubscriptionListData(
      subscriptions: subscriptions,
      total: data['total'] as int? ?? subscriptions.length,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
    );
  }

  @override
  Future<SubscriptionInfo> loadSubscriptionDetail(String id) async {
    final data = await ApiClient.instance.get('/admin/subscriptions/$id');
    return SubscriptionInfo.fromJson(data);
  }

  @override
  Future<SubscriptionInfo> updateSubscriptionStatus(
      String id, String targetStatus) async {
    final data = await ApiClient.instance.put(
      '/admin/subscriptions/$id/status',
      body: {'targetStatus': targetStatus},
    );
    return SubscriptionInfo.fromJson(data);
  }

  // ── Services (AdminServiceController) ─────────────────────────────

  @override
  Future<SubscriptionServiceListData> loadServices({
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    final query = Uri(queryParameters: params).query;
    final data =
        await ApiClient.instance.get('/admin/subscription-services?$query');
    final items = data['items'] as List<dynamic>? ?? [];
    final services = items
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionServiceInfo.fromJson)
        .toList();
    return SubscriptionServiceListData(
      services: services,
      total: data['total'] as int? ?? services.length,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
    );
  }

  @override
  Future<SubscriptionServiceInfo> createService(
      Map<String, dynamic> body) async {
    final data = await ApiClient.instance
        .post('/admin/subscription-services', body: body);
    return SubscriptionServiceInfo.fromJson(data);
  }

  @override
  Future<SubscriptionServiceInfo> loadServiceDetail(String id) async {
    final data =
        await ApiClient.instance.get('/admin/subscription-services/$id');
    return SubscriptionServiceInfo.fromJson(data);
  }

  @override
  Future<SubscriptionServiceInfo> updateServiceStatus(
      String id, String targetStatus) async {
    final data = await ApiClient.instance.put(
      '/admin/subscription-services/$id/status',
      body: {'targetStatus': targetStatus},
    );
    return SubscriptionServiceInfo.fromJson(data);
  }

  @override
  Future<SubscriptionServiceInfo> updateServiceQuota(
      String id, int deviceQuota) async {
    final data = await ApiClient.instance.put(
      '/admin/subscription-services/$id/quota',
      body: {'deviceQuota': deviceQuota},
    );
    return SubscriptionServiceInfo.fromJson(data);
  }
}
