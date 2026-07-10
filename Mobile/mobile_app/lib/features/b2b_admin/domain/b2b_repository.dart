class B2bFarmSummary {
  const B2bFarmSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.ownerName,
    required this.livestockCount,
    required this.region,
    this.ownerId,
    this.deviceCount = 0,
    this.workerCount = 0,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.areaHectares,
  });

  final String id;
  final String name;
  final String status;
  final String ownerName;
  final int? ownerId;
  final int livestockCount;
  final String region;
  final int deviceCount;
  final int workerCount;
  final String? createdAt;
  final double? latitude;
  final double? longitude;
  final double? areaHectares;
}

class B2bUserSummary {
  const B2bUserSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  final int id;
  final String name;
  final String phone;
  final String role;
}

class B2bDashboardData {
  const B2bDashboardData({
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

abstract class B2bRepository {
  Future<B2bDashboardData> loadDashboard();
  Future<B2bContractData> loadContract();
  Future<bool> createFarm(Map<String, dynamic> body);
  Future<List<B2bUserSummary>> loadUsers({String? role});
  Future<bool> changeOwner(String farmId, int ownerId);
}
