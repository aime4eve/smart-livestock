import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_repository.dart';

class B2bApiRepository implements B2bRepository {
  const B2bApiRepository();

  @override
  Future<B2bDashboardData> loadDashboard() async {
    final data = await ApiClient.instance.get('/b2b/dashboard');
    final farms = (data['farms'] as List?)
            ?.map((f) => B2bFarmSummary(
                  id: f['id'] as String,
                  name: f['name'] as String,
                  status: f['status'] as String? ?? 'active',
                  ownerName: f['ownerName'] as String? ?? '',
                  livestockCount: f['livestockCount'] as int? ?? 0,
                  region: f['region'] as String? ?? '',
                  deviceCount: f['deviceCount'] as int? ?? 0,
                  workerCount: f['workerCount'] as int? ?? 0,
                ))
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
    final data = await ApiClient.instance.get('/b2b/contract');
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
}
