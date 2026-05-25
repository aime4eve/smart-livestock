class SubscriptionServiceListViewData {
  const SubscriptionServiceListViewData({
    this.services = const [],
    this.total = 0,
    this.message,
  });

  final List<Map<String, dynamic>> services;
  final int total;
  final String? message;

  bool get isEmpty => services.isEmpty;
}

abstract class SubscriptionServiceRepository {
  Future<SubscriptionServiceListViewData> getServices({String? tenantId, String? status});
  Future<bool> createService(Map<String, dynamic> data);
  Future<bool> renewService(String serviceId, String endDate);
  Future<bool> revokeService(String serviceId);
}
