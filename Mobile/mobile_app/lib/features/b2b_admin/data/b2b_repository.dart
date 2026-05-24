import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class B2bFarmSummary {
  const B2bFarmSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.ownerName,
    required this.livestockCount,
    required this.region,
    this.deviceCount = 0,
    this.workerCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String status;
  final String ownerName;
  final int livestockCount;
  final String region;
  final int deviceCount;
  final int workerCount;
  final String? createdAt;
}

class B2bDashboardData {
  const B2bDashboardData({
    required this.viewState,
    this.totalFarms = 0,
    this.totalLivestock = 0,
    this.totalDevices = 0,
    this.pendingAlerts = 0,
    this.monthlyRevenue = 0.0,
    this.deviceOnlineRate = 0.0,
    this.partnerName,
    this.billingModel,
    this.alertSummary = const [],
    this.farms = const [],
    this.contractStatus,
    this.contractExpiresAt,
    this.message,
  });

  final ViewState viewState;
  final int totalFarms;
  final int totalLivestock;
  final int totalDevices;
  final int pendingAlerts;
  final double monthlyRevenue;
  final double deviceOnlineRate;
  final String? partnerName;
  final String? billingModel;
  final List<Map<String, dynamic>> alertSummary;
  final List<B2bFarmSummary> farms;
  final String? contractStatus;
  final String? contractExpiresAt;
  final String? message;
}

class B2bContractData {
  const B2bContractData({
    required this.viewState,
    this.id,
    this.status,
    this.effectiveTier,
    this.revenueShareRatio,
    this.startedAt,
    this.expiresAt,
    this.signedBy,
    this.partnerName,
    this.partnerTenantId,
    this.contractId,
    this.billingModel,
    this.deploymentType,
    this.serviceStatus,
    this.serviceTier,
    this.lastHeartbeatAt,
    this.deviceQuota,
    this.serviceExpiresAt,
    this.message,
  });

  final ViewState viewState;
  final String? id;
  final String? status;
  final String? effectiveTier;
  final double? revenueShareRatio;
  final String? startedAt;
  final String? expiresAt;
  final String? signedBy;
  final String? partnerName;
  final String? partnerTenantId;
  final String? contractId;
  final String? billingModel;
  final String? deploymentType;
  final String? serviceStatus;
  final String? serviceTier;
  final String? lastHeartbeatAt;
  final int? deviceQuota;
  final String? serviceExpiresAt;
  final String? message;
}

class B2bRepository {
  B2bRepository();

  // _mockCreatedFarms removed

  B2bDashboardData loadDashboard(ViewState viewState) {
    if (viewState != ViewState.normal) {
      return B2bDashboardData(viewState: viewState);
    }

    return _loadDashboardFromCache();
  }




  Future<bool> createFarm(
    String name, {
    String? ownerName,
    String? contactPhone,
    String? region,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (ownerName != null) body['ownerName'] = ownerName;
    if (contactPhone != null) body['contactPhone'] = contactPhone;
    if (region != null) body['region'] = region;
    return ApiCache.instance.createB2bFarmRemote('b2b_admin', body);
  }

  B2bContractData loadContract(ViewState viewState) {
    if (viewState != ViewState.normal) {
      return B2bContractData(viewState: viewState);
    }

    return _loadContractFromCache();
  }

  B2bDashboardData _loadDashboardFromCache() {
    try {
      final data = ApiCache.instance.b2bDashboard;
      if (data == null) {
        return const B2bDashboardData(viewState: ViewState.normal);
      }
      final farms = (data['farms'] as List?)
              ?.map((f) => B2bFarmSummary(
                    id: f['id'] as String,
                    name: f['name'] as String,
                    status: f['status'] as String,
                    ownerName: f['ownerName'] as String? ?? '',
                    livestockCount: f['livestockCount'] as int? ?? 0,
                    region: f['region'] as String? ?? '',
                    deviceCount: f['deviceCount'] as int? ?? 0,
                    workerCount: f['workerCount'] as int? ?? 0,
                  ))
              .toList() ??
          [];

      final alertSummaryRaw = data['alertSummary'] as List?;
      final alertSummary = alertSummaryRaw
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          <Map<String, dynamic>>[];

      return B2bDashboardData(
        viewState: ViewState.normal,
        totalFarms: data['totalFarms'] as int? ?? 0,
        totalLivestock: data['totalLivestock'] as int? ?? 0,
        totalDevices: data['totalDevices'] as int? ?? 0,
        pendingAlerts: data['pendingAlerts'] as int? ?? 0,
        monthlyRevenue: (data['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
        deviceOnlineRate:
            (data['deviceOnlineRate'] as num?)?.toDouble() ?? 0.0,
        partnerName: data['partnerName'] as String?,
        billingModel: data['billingModel'] as String?,
        alertSummary: alertSummary,
        farms: farms,
        contractStatus: data['contractStatus'] as String?,
        contractExpiresAt: data['contractExpiresAt'] as String?,
      );
    } catch (_) {
      return const B2bDashboardData(viewState: ViewState.normal);
    }
  }

  B2bContractData _loadContractFromCache() {
    try {
      final data = ApiCache.instance.b2bContract;
      if (data == null) {
        return const B2bContractData(viewState: ViewState.normal);
      }

      final sub = data['subscriptionService'] as Map?;

      return B2bContractData(
        viewState: ViewState.normal,
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
    } catch (_) {
      return const B2bContractData(viewState: ViewState.normal);
    }
  }
}
