class SubscriptionServiceInfo {
  const SubscriptionServiceInfo({
    required this.id,
    this.tenantId,
    this.serviceName,
    this.serviceKeyPrefix,
    this.effectiveTier,
    this.deviceQuota,
    this.status,
    this.lastHeartbeatAt,
    this.startedAt,
    this.expiresAt,
  });

  final String id;
  final int? tenantId;
  final String? serviceName;
  final String? serviceKeyPrefix;
  final String? effectiveTier;
  final int? deviceQuota;
  final String? status;
  final String? lastHeartbeatAt;
  final String? startedAt;
  final String? expiresAt;

  factory SubscriptionServiceInfo.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return SubscriptionServiceInfo(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      tenantId: json['tenantId'] as int?,
      serviceName: json['serviceName'] as String?,
      serviceKeyPrefix: json['serviceKeyPrefix'] as String?,
      effectiveTier: json['effectiveTier'] as String?,
      deviceQuota: json['deviceQuota'] as int?,
      status: json['status'] as String?,
      lastHeartbeatAt: json['lastHeartbeatAt'] as String?,
      startedAt: json['startedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
    );
  }

  bool get isActive => status?.toUpperCase() == 'ACTIVE';

  String get statusLabel => switch (status?.toUpperCase()) {
        'ACTIVE' => '生效中',
        'EXPIRED' => '已过期',
        'REVOKED' => '已撤销',
        _ => status ?? '未知',
      };
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.id,
    this.tenantId,
    this.tier,
    this.billingModel,
    this.status,
    this.billingCycle,
    this.startedAt,
    this.expiresAt,
    this.trialEndsAt,
    this.cancelledAt,
    this.effectiveTier,
  });

  final String id;
  final int? tenantId;
  final String? tier;
  final String? billingModel;
  final String? status;
  final String? billingCycle;
  final String? startedAt;
  final String? expiresAt;
  final String? trialEndsAt;
  final String? cancelledAt;
  final String? effectiveTier;

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return SubscriptionInfo(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      tenantId: json['tenantId'] as int?,
      tier: json['tier'] as String?,
      billingModel: json['billingModel'] as String?,
      status: json['status'] as String?,
      billingCycle: json['billingCycle'] as String?,
      startedAt: json['startedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      trialEndsAt: json['trialEndsAt'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      effectiveTier: json['effectiveTier'] as String?,
    );
  }

  bool get isActive => status?.toUpperCase() == 'ACTIVE';
  bool get isSuspended => status?.toUpperCase() == 'SUSPENDED';
  bool get isCancelled => status?.toUpperCase() == 'CANCELLED';
}

class SubscriptionServiceListData {
  const SubscriptionServiceListData({
    required this.services,
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
  });

  final List<SubscriptionServiceInfo> services;
  final int total;
  final int page;
  final int pageSize;

  bool get isEmpty => services.isEmpty;
}

class SubscriptionListData {
  const SubscriptionListData({
    required this.subscriptions,
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
  });

  final List<SubscriptionInfo> subscriptions;
  final int total;
  final int page;
  final int pageSize;

  bool get isEmpty => subscriptions.isEmpty;
}

abstract class SubscriptionServiceRepository {
  // Subscriptions (AdminSubscriptionController)
  Future<SubscriptionListData> loadSubscriptions({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? tier,
  });
  Future<SubscriptionInfo> loadSubscriptionDetail(String id);
  Future<SubscriptionInfo> updateSubscriptionStatus(
      String id, String targetStatus);

  // Services (AdminServiceController)
  Future<SubscriptionServiceListData> loadServices({
    int page = 1,
    int pageSize = 20,
  });
  Future<SubscriptionServiceInfo> createService(Map<String, dynamic> body);
  Future<SubscriptionServiceInfo> loadServiceDetail(String id);
  Future<SubscriptionServiceInfo> updateServiceStatus(
      String id, String targetStatus);
  Future<SubscriptionServiceInfo> updateServiceQuota(
      String id, int deviceQuota);
}
