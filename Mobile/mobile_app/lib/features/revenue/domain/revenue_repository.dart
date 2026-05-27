class RevenuePeriod {
  const RevenuePeriod({
    required this.id,
    required this.periodLabel,
    required this.totalRevenue,
    required this.platformShare,
    required this.partnerShare,
    required this.status,
    this.revenueShareRatio,
    this.confirmedAt,
  });

  final String id;
  final String periodLabel;
  final double totalRevenue;
  final double platformShare;
  final double partnerShare;
  final String status;
  final double? revenueShareRatio;
  final String? confirmedAt;

  factory RevenuePeriod.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');

    final periodStart = json['periodStart'] as String? ?? '';
    final periodLabel = periodStart.length >= 7
        ? '${periodStart.substring(0, 4)}年${int.parse(periodStart.substring(5, 7))}月'
        : periodStart;

    final totalRevenue =
        ((json['grossAmount'] as num?)?.toDouble() ?? 0.0) / 100.0;
    final platformShare =
        ((json['platformShare'] as num?)?.toDouble() ?? 0.0) / 100.0;
    final partnerShare =
        ((json['partnerShare'] as num?)?.toDouble() ?? 0.0) / 100.0;

    return RevenuePeriod(
      id: id,
      periodLabel: periodLabel,
      totalRevenue: totalRevenue,
      platformShare: platformShare,
      partnerShare: partnerShare,
      status: (json['status'] as String? ?? 'PENDING').toLowerCase(),
      revenueShareRatio: (json['revenueShareRatio'] as num?)?.toDouble(),
      confirmedAt: json['settledAt'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isPlatformConfirmed => status == 'platform_confirmed';
  bool get isPartnerConfirmed => status == 'partner_confirmed';
  bool get isSettled => status == 'settled';

  bool get platformConfirmed => !isPending;
  bool get partnerConfirmed => isPartnerConfirmed || isSettled;
}

class RevenueListViewData {
  const RevenueListViewData({
    this.periods = const [],
    this.total = 0,
  });

  final List<RevenuePeriod> periods;
  final int total;

  bool get isEmpty => periods.isEmpty;
}

class RevenueDetailViewData {
  const RevenueDetailViewData({required this.period});
  final RevenuePeriod period;
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
}

abstract class RevenueRepository {
  // Admin-scoped (platform_admin)
  Future<RevenueListViewData> getPeriods();
  Future<RevenueDetailViewData> getPeriodDetail(String periodId);
  Future<bool> confirmPeriod(String periodId);
  Future<bool> calculateRevenue({
    required String contractId,
    required String periodStart,
    required String periodEnd,
    required int grossAmountCents,
  });
  Future<bool> recalculatePeriod(String periodId, int grossAmountCents);

  // App-scoped (tenant user, B2B admin)
  Future<RevenueListViewData> getAppPeriods();
  Future<bool> confirmAsPartner(String periodId);
}
