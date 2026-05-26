import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/api/api_exception.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_repository.dart';

String _parseId(dynamic raw) =>
    raw is int ? raw.toString() : (raw as String? ?? '');

class B2bApiRepository implements B2bRepository {
  const B2bApiRepository();

  @override
  Future<B2bDashboardData> loadDashboard() async {
    final Map<String, dynamic> data;
    try {
      data = await ApiClient.instance.get('/b2b/dashboard');
    } on NotFoundException {
      return const B2bDashboardData();
    }
    final farms = (data['farms'] as List?)
            ?.map((f) {
              final fm = f as Map<String, dynamic>;
              return B2bFarmSummary(
                id: _parseId(fm['id']),
                name: fm['name'] as String,
                status: fm['status'] as String? ?? 'active',
                ownerName: fm['ownerName'] as String? ?? '',
                ownerId: fm['ownerId'] as int?,
                livestockCount: fm['livestockCount'] as int? ?? 0,
                region: fm['region'] as String? ?? '',
                deviceCount: fm['deviceCount'] as int? ?? 0,
                workerCount: fm['workerCount'] as int? ?? 0,
              );
            })
            .toList() ??
        [];
    final alertSummary = (data['alertSummary'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];
    return B2bDashboardData(
      totalFarms: data['totalFarms'] as int? ?? 0,
      totalLivestock: data['totalLivestock'] as int? ?? 0,
      totalDevices: data['totalDevices'] as int? ?? 0,
      pendingAlerts: data['pendingAlerts'] as int? ?? 0,
      monthlyRevenue: (data['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
      deviceOnlineRate: (data['deviceOnlineRate'] as num?)?.toDouble() ?? 0.0,
      partnerName: data['partnerName'] as String?,
      billingModel: data['billingModel'] as String?,
      alertSummary: alertSummary,
      farms: farms,
      contractStatus: data['contractStatus'] as String?,
      contractExpiresAt: data['contractExpiresAt'] as String?,
    );
  }

  @override
  Future<B2bContractData> loadContract() async {
    final Map<String, dynamic> data;
    try {
      data = await ApiClient.instance.get('/b2b/contract');
    } on NotFoundException {
      return const B2bContractData();
    }
    final sub = data['subscriptionService'] as Map?;
    return B2bContractData(
      id: data['id'] as String?,
      status: data['status'] as String?,
      effectiveTier: data['effectiveTier'] as String?,
      revenueShareRatio: (data['revenueShareRatio'] as num?)?.toDouble(),
      startedAt: data['startedAt'] as String?,
      expiresAt: data['expiresAt'] as String?,
      signedBy: data['signedBy'] as String?,
      partnerName: data['partnerName'] as String?,
      partnerTenantId: data['partnerTenantId'] as String?,
      contractId: data['contractId'] as String?,
      billingModel: data['billingModel'] as String?,
      deploymentType: data['deploymentType'] as String?,
      serviceStatus: sub?['serviceStatus'] as String?,
      serviceTier: sub?['serviceTier'] as String?,
      lastHeartbeatAt: sub?['lastHeartbeatAt'] as String?,
      deviceQuota: sub?['deviceQuota'] as int?,
      serviceExpiresAt: sub?['serviceExpiresAt'] as String?,
    );
  }

  @override
  Future<bool> createFarm(Map<String, dynamic> body) async {
    await ApiClient.instance.post('/farms', body: body);
    return true;
  }

  @override
  Future<List<B2bUserSummary>> loadUsers({String? role}) async {
    final uri = role != null ? '/b2b/users?role=$role' : '/b2b/users';
    final Map<String, dynamic> data = await ApiClient.instance.get(uri);
    final items = data['items'] as List? ?? [];
    return items.map((e) {
      final m = e as Map<String, dynamic>;
      return B2bUserSummary(
        id: m['id'] as int,
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        role: m['role'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<bool> changeOwner(String farmId, int ownerId) async {
    await ApiClient.instance.put('/farms/$farmId/owner', body: {'ownerId': ownerId});
    return true;
  }
}
