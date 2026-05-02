import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/data/mock_subscription_service_repository.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/domain/subscription_service_repository.dart';

class LiveSubscriptionServiceRepository
    implements SubscriptionServiceRepository {
  LiveSubscriptionServiceRepository();

  static final MockSubscriptionServiceRepository _fallback =
      MockSubscriptionServiceRepository();

  @override
  SubscriptionServiceListViewData getServices({String? tenantId, String? status}) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getServices(tenantId: tenantId, status: status);
    }
    var all =
        List<Map<String, dynamic>>.from(cache.subscriptionServices);
    if (tenantId != null && tenantId.isNotEmpty) {
      all = all.where((s) => s['tenantId'] == tenantId).toList();
    }
    if (status != null && status.isNotEmpty) {
      all = all.where((s) => s['status'] == status).toList();
    }
    return SubscriptionServiceListViewData(
      viewState: all.isEmpty ? ViewState.empty : ViewState.normal,
      services: all,
      total: all.length,
      message: all.isEmpty ? '暂无订阅服务' : null,
    );
  }

  @override
  Future<bool> createService(Map<String, dynamic> data) async {
    return _fallback.createService(data);
  }

  @override
  Future<bool> renewService(String serviceId, String endDate) async {
    return _fallback.renewService(serviceId, endDate);
  }

  @override
  Future<bool> revokeService(String serviceId) async {
    return _fallback.revokeService(serviceId);
  }
}
