class AnomalyScoreData {
  const AnomalyScoreData({
    required this.livestockId,
    required this.anomalyScore,
    required this.anomalyType,
    this.assessedAt,
    this.nEff,
    this.capabilityUsed,
  });

  final String livestockId;
  final double anomalyScore; // 0.0 - 1.0
  final String anomalyType; // normal / circadian_disruption / abrupt_change / multivariate
  final DateTime? assessedAt;
  final int? nEff;
  final String? capabilityUsed;

  factory AnomalyScoreData.fromJson(Map<String, dynamic> json) {
    return AnomalyScoreData(
      livestockId: (json['livestockId'] ?? '').toString(),
      anomalyScore: (json['anomalyScore'] as num?)?.toDouble() ?? 0.0,
      anomalyType: json['anomalyType'] as String? ?? 'normal',
      assessedAt: json['assessedAt'] != null || json['createdAt'] != null
          ? DateTime.tryParse(
              (json['assessedAt'] ?? json['createdAt']).toString())
          : null,
      nEff: json['nEff'] as int?,
      capabilityUsed: json['capabilityUsed'] as String?,
    );
  }
}

class AnomalyScoreHistoryItem {
  const AnomalyScoreHistoryItem({
    required this.anomalyScore,
    required this.anomalyType,
    required this.assessedAt,
  });

  final double anomalyScore;
  final String anomalyType;
  final DateTime assessedAt;

  factory AnomalyScoreHistoryItem.fromJson(Map<String, dynamic> json) {
    return AnomalyScoreHistoryItem(
      anomalyScore: (json['anomalyScore'] as num?)?.toDouble() ?? 0.0,
      anomalyType: json['anomalyType'] as String? ?? 'normal',
      assessedAt: json['assessedAt'] != null || json['createdAt'] != null
          ? DateTime.tryParse(
                  (json['assessedAt'] ?? json['createdAt']).toString()) ??
              DateTime.now()
          : DateTime.now(),
    );
  }
}
