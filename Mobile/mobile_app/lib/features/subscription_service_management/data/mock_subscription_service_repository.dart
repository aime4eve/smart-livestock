import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/domain/subscription_service_repository.dart';

class MockSubscriptionServiceRepository
    implements SubscriptionServiceRepository {
  MockSubscriptionServiceRepository();

  static final List<Map<String, dynamic>> _services = [
    {
      'id': 'svc_001',
      'tenantId': 'tenant_001',
      'tenantName': '华东示范牧场',
      'tier': 'pro',
      'status': 'active',
      'startDate': '2025-06-01',
      'endDate': '2026-06-01',
      'livestockCount': 200,
      'createdAt': '2025-05-20T10:00:00+08:00',
    },
    {
      'id': 'svc_002',
      'tenantId': 'tenant_002',
      'tenantName': '西部高原牧场',
      'tier': 'enterprise',
      'status': 'active',
      'startDate': '2025-08-15',
      'endDate': '2026-08-15',
      'livestockCount': 200,
      'createdAt': '2025-08-01T09:30:00+08:00',
    },
    {
      'id': 'svc_003',
      'tenantId': 'tenant_003',
      'tenantName': '东北黑土地牧场',
      'tier': 'basic',
      'status': 'active',
      'startDate': '2025-12-01',
      'endDate': '2026-12-01',
      'livestockCount': 250,
      'createdAt': '2025-11-15T14:00:00+08:00',
    },
    {
      'id': 'svc_004',
      'tenantId': 'tenant_004',
      'tenantName': '华南热带牧场',
      'tier': 'trial',
      'status': 'expired',
      'startDate': '2025-11-01',
      'endDate': '2026-02-01',
      'livestockCount': 100,
      'createdAt': '2025-10-20T11:00:00+08:00',
    },
  ];

  @override
  SubscriptionServiceListViewData getServices({String? tenantId, String? status}) {
    var filtered = List<Map<String, dynamic>>.from(_services);
    if (tenantId != null && tenantId.isNotEmpty) {
      filtered = filtered.where((s) => s['tenantId'] == tenantId).toList();
    }
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((s) => s['status'] == status).toList();
    }
    return SubscriptionServiceListViewData(
      viewState: filtered.isEmpty ? ViewState.empty : ViewState.normal,
      services: filtered,
      total: filtered.length,
      message: filtered.isEmpty ? '暂无订阅服务' : null,
    );
  }

  @override
  Future<bool> createService(Map<String, dynamic> data) async {
    final newService = Map<String, dynamic>.from(data);
    newService['id'] = 'svc_${DateTime.now().millisecondsSinceEpoch}';
    _services.add(newService);
    return true;
  }

  @override
  Future<bool> renewService(String serviceId, String endDate) async {
    final index = _services.indexWhere((s) => s['id'] == serviceId);
    if (index == -1) return false;
    _services[index] = {..._services[index], 'endDate': endDate, 'status': 'active'};
    return true;
  }

  @override
  Future<bool> revokeService(String serviceId) async {
    final index = _services.indexWhere((s) => s['id'] == serviceId);
    if (index == -1) return false;
    _services[index] = {..._services[index], 'status': 'revoked'};
    return true;
  }
}
