import 'package:smart_livestock_demo/core/models/view_state.dart';

class RevenuePeriod {
  const RevenuePeriod({
    required this.id,
    required this.periodLabel,
    required this.totalRevenue,
    required this.platformShare,
    required this.partnerShare,
    required this.status,
    this.confirmedAt,
  });

  final String id;
  final String periodLabel;
  final double totalRevenue;
  final double platformShare;
  final double partnerShare;
  final String status; // pending, confirmed, paid
  final String? confirmedAt;

  factory RevenuePeriod.fromJson(Map<String, dynamic> json) {
    return RevenuePeriod(
      id: json['id'] as String,
      periodLabel: json['periodLabel'] as String? ?? '',
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      platformShare: (json['platformShare'] as num?)?.toDouble() ?? 0.0,
      partnerShare: (json['partnerShare'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      confirmedAt: json['confirmedAt'] as String?,
    );
  }
}

class RevenueListViewData {
  const RevenueListViewData({
    this.viewState = ViewState.normal,
    this.periods = const [],
    this.total = 0,
    this.message,
  });

  final ViewState viewState;
  final List<RevenuePeriod> periods;
  final int total;
  final String? message;
}

class RevenueFarmDetail {
  const RevenueFarmDetail({
    required this.farmName,
    required this.livestockCount,
    required this.deviceUnitPrice,
    required this.deviceFee,
    required this.shareAmount,
  });

  final String farmName;
  final int livestockCount;
  final double deviceUnitPrice;
  final double deviceFee;
  final double shareAmount;

  factory RevenueFarmDetail.fromJson(Map<String, dynamic> json) {
    return RevenueFarmDetail(
      farmName: json['farmName'] as String? ?? '',
      livestockCount: json['livestockCount'] as int? ?? 0,
      deviceUnitPrice: (json['deviceUnitPrice'] as num?)?.toDouble() ?? 0.0,
      deviceFee: (json['deviceFee'] as num?)?.toDouble() ?? 0.0,
      shareAmount: (json['shareAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RevenueDetailViewData {
  const RevenueDetailViewData({
    this.viewState = ViewState.normal,
    this.period,
    this.totalDeviceFee = 0.0,
    this.revenueShareRatio = 0.0,
    this.platformConfirmed = false,
    this.partnerConfirmed = false,
    this.calculatedAt,
    this.farmDetails = const [],
    this.message,
  });

  final ViewState viewState;
  final RevenuePeriod? period;
  final double totalDeviceFee;
  final double revenueShareRatio;
  final bool platformConfirmed;
  final bool partnerConfirmed;
  final String? calculatedAt;
  final List<RevenueFarmDetail> farmDetails;
  final String? message;
}

abstract class RevenueRepository {
  RevenueListViewData getPeriods({String? partnerId});
  RevenueDetailViewData getPeriodDetail(String periodId);
  Future<bool> confirmPeriod(String periodId);
  Future<bool> calculateRevenue(String periodId);
}
