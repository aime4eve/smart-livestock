import 'package:smart_livestock_demo/core/models/view_state.dart';

class SubscriptionServiceListViewData {
  const SubscriptionServiceListViewData({
    this.viewState = ViewState.normal,
    this.services = const [],
    this.total = 0,
    this.message,
  });

  final ViewState viewState;
  final List<Map<String, dynamic>> services;
  final int total;
  final String? message;
}

abstract class SubscriptionServiceRepository {
  SubscriptionServiceListViewData getServices({String? tenantId, String? status});
  Future<bool> createService(Map<String, dynamic> data);
  Future<bool> renewService(String serviceId, String endDate);
  Future<bool> revokeService(String serviceId);
}
