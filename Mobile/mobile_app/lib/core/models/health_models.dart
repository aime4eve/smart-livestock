import 'package:hkt_livestock_agentic/core/models/twin_models.dart';

// Re-export existing twin_models which already define:
// TemperatureBaseline, TemperatureRecord, DigestiveHealth, MotilityRecord,
// EstrusScore, EstrusTrendPoint, HerdHealthMetrics, ContactTrace,
// FeverViewData, DigestiveViewData, EstrusViewData, EpidemicViewData,
// SceneSummaryFever, SceneSummaryDigestive, SceneSummaryEstrus, SceneSummaryEpidemic,
// TwinSceneSummary, TwinOverviewStats

class HealthOverviewResponse {
  const HealthOverviewResponse({
    required this.stats,
    required this.sceneSummary,
    this.pendingTasks = const [],
  });

  final TwinOverviewStats? stats;
  final TwinSceneSummary? sceneSummary;
  final List<TwinPendingTask> pendingTasks;

  factory HealthOverviewResponse.fromJson(Map<String, dynamic> json) {
    return HealthOverviewResponse(
      stats: json['stats'] != null ? _parseStats(json['stats']) : null,
      sceneSummary: json['sceneSummary'] != null
          ? _parseSceneSummary(json['sceneSummary'])
          : null,
      pendingTasks: (json['pendingTasks'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(_parsePendingTask)
              .toList() ??
          [],
    );
  }

  static TwinOverviewStats _parseStats(Map<String, dynamic> m) {
    return TwinOverviewStats(
      totalLivestock: m['totalLivestock'] as int? ?? 0,
      healthyRate: (m['healthyRate'] as num?)?.toDouble() ?? 0.0,
      alertCount: m['alertCount'] as int? ?? 0,
      criticalCount: m['criticalCount'] as int? ?? 0,
      deviceOnlineRate: (m['deviceOnlineRate'] as num?)?.toDouble() ?? 0.0,
      livestockCaption: m['livestockCaption'] as String? ?? '',
      alertCaption: m['alertCaption'] as String? ?? '',
      healthCaption: m['healthCaption'] as String? ?? '',
      deviceCaption: m['deviceCaption'] as String? ?? '',
      healthTrend: m['healthTrend'] as String? ?? '',
      livestockTrend: m['livestockTrend'] as String? ?? '',
    );
  }

  static TwinSceneSummary _parseSceneSummary(Map<String, dynamic> m) {
    return TwinSceneSummary(
      fever: m['fever'] != null
          ? SceneSummaryFever(
              abnormalCount: m['fever']['abnormalCount'] as int? ?? 0,
              criticalCount: m['fever']['criticalCount'] as int? ?? 0,
            )
          : const SceneSummaryFever(abnormalCount: 0, criticalCount: 0),
      digestive: m['digestive'] != null
          ? SceneSummaryDigestive(
              abnormalCount: m['digestive']['abnormalCount'] as int? ?? 0,
              watchCount: m['digestive']['watchCount'] as int? ?? 0,
            )
          : const SceneSummaryDigestive(abnormalCount: 0, watchCount: 0),
      estrus: m['estrus'] != null
          ? SceneSummaryEstrus(
              highScoreCount: m['estrus']['highScoreCount'] as int? ?? 0,
              breedingAdvice: m['estrus']['breedingAdvice'] as bool? ?? false,
            )
          : const SceneSummaryEstrus(highScoreCount: 0, breedingAdvice: false),
      epidemic: m['epidemic'] != null
          ? SceneSummaryEpidemic(
              status: m['epidemic']['status'] as String? ?? 'Normal',
              abnormalRate: (m['epidemic']['abnormalRate'] as num?)?.toDouble() ?? 0.0,
            )
          : const SceneSummaryEpidemic(status: 'Normal', abnormalRate: 0.0),
    );
  }

  static TwinPendingTask _parsePendingTask(Map<String, dynamic> m) {
    return TwinPendingTask(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      subtitle: m['subtitle'] as String? ?? '',
      routePath: m['routePath'] as String? ?? '',
      severity: m['severity'] as String? ?? 'INFO',
    );
  }
}

class FeverListItem {
  const FeverListItem({
    required this.livestockId,
    required this.livestockCode,
    this.breed,
    required this.baselineTemp,
    required this.currentTemp,
    required this.delta,
    required this.status,
    this.conclusion,
  });

  final String livestockId;
  final String livestockCode;
  final String? breed;
  final double baselineTemp;
  final double currentTemp;
  final double delta;
  final String status;
  final String? conclusion;

  factory FeverListItem.fromJson(Map<String, dynamic> m) {
    return FeverListItem(
      livestockId: (m['livestockId'] ?? '').toString(),
      livestockCode: (m['livestockCode'] ?? '') as String,
      breed: m['breed'] as String?,
      baselineTemp: (m['baselineTemp'] as num?)?.toDouble() ?? 38.5,
      currentTemp: (m['currentTemp'] as num?)?.toDouble() ?? 38.5,
      delta: (m['delta'] as num?)?.toDouble() ?? 0.0,
      status: (m['status'] ?? 'NORMAL') as String,
      conclusion: m['conclusion'] as String?,
    );
  }
}

class FeverDetailData {
  const FeverDetailData({
    required this.livestockId,
    required this.livestockCode,
    required this.baselineTemp,
    required this.threshold,
    required this.status,
    this.conclusion,
    this.recent72h = const [],
  });

  final String livestockId;
  final String livestockCode;
  final double baselineTemp;
  final double threshold;
  final String status;
  final String? conclusion;
  final List<TemperatureRecord> recent72h;

  factory FeverDetailData.fromJson(Map<String, dynamic> m) {
    return FeverDetailData(
      livestockId: (m['livestockId'] ?? '').toString(),
      livestockCode: (m['livestockCode'] ?? '') as String,
      baselineTemp: (m['baselineTemp'] as num?)?.toDouble() ?? 38.5,
      threshold: (m['threshold'] as num?)?.toDouble() ?? 39.5,
      status: (m['status'] ?? 'NORMAL') as String,
      conclusion: m['conclusion'] as String?,
      recent72h: (m['recent72h'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => TemperatureRecord(
                    livestockId: (m['livestockId'] ?? '').toString(),
                    temperature: (e['temperature'] as num?)?.toDouble() ?? 38.5,
                    timestamp: DateTime.parse(e['timestamp'] as String),
                  ))
              .toList() ??
          [],
    );
  }
}

class DigestiveListItem {
  const DigestiveListItem({
    required this.livestockId,
    required this.livestockCode,
    this.breed,
    required this.motilityBaseline,
    required this.currentFrequency,
    required this.status,
    this.advice,
  });

  final String livestockId;
  final String livestockCode;
  final String? breed;
  final double motilityBaseline;
  final double currentFrequency;
  final String status;
  final String? advice;

  factory DigestiveListItem.fromJson(Map<String, dynamic> m) {
    return DigestiveListItem(
      livestockId: (m['livestockId'] ?? '').toString(),
      livestockCode: (m['livestockCode'] ?? '') as String,
      breed: m['breed'] as String?,
      motilityBaseline: (m['motilityBaseline'] as num?)?.toDouble() ?? 3.0,
      currentFrequency: (m['currentFrequency'] as num?)?.toDouble() ?? 3.0,
      status: (m['status'] ?? 'NORMAL') as String,
      advice: m['advice'] as String?,
    );
  }
}

class DigestiveDetailData {
  const DigestiveDetailData({
    required this.livestockId,
    required this.livestockCode,
    required this.motilityBaseline,
    required this.status,
    this.advice,
    this.recent24h = const [],
  });

  final String livestockId;
  final String livestockCode;
  final double motilityBaseline;
  final String status;
  final String? advice;
  final List<MotilityRecord> recent24h;

  factory DigestiveDetailData.fromJson(Map<String, dynamic> m) {
    return DigestiveDetailData(
      livestockId: (m['livestockId'] ?? '').toString(),
      livestockCode: (m['livestockCode'] ?? '') as String,
      motilityBaseline: (m['motilityBaseline'] as num?)?.toDouble() ?? 3.0,
      status: (m['status'] ?? 'NORMAL') as String,
      advice: m['advice'] as String?,
      recent24h: (m['recent24h'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => MotilityRecord(
                    livestockId: (m['livestockId'] ?? '').toString(),
                    frequency: (e['frequency'] as num?)?.toDouble() ?? 3.0,
                    intensity: (e['intensity'] as num?)?.toDouble() ?? 50.0,
                    timestamp: DateTime.parse(e['timestamp'] as String),
                  ))
              .toList() ??
          [],
    );
  }
}

class EstrusListItem {
  const EstrusListItem({
    required this.livestockId,
    required this.livestockCode,
    this.breed,
    this.gender,
    required this.score,
    this.stepIncreasePercent,
    this.tempDelta,
    this.distanceDelta,
    this.timestamp,
    this.advice,
  });

  final String livestockId;
  final String livestockCode;
  final String? breed;
  final String? gender;
  final int score;
  final int? stepIncreasePercent;
  final double? tempDelta;
  final double? distanceDelta;
  final DateTime? timestamp;
  final String? advice;

  factory EstrusListItem.fromJson(Map<String, dynamic> m) {
    return EstrusListItem(
      livestockId: (m['livestockId'] ?? '').toString(),
      livestockCode: (m['livestockCode'] ?? '') as String,
      breed: m['breed'] as String?,
      gender: m['gender'] as String?,
      score: m['score'] as int? ?? 0,
      stepIncreasePercent: m['stepIncreasePercent'] as int?,
      tempDelta: (m['tempDelta'] as num?)?.toDouble(),
      distanceDelta: (m['distanceDelta'] as num?)?.toDouble(),
      timestamp: m['timestamp'] != null ? DateTime.parse(m['timestamp'] as String) : null,
      advice: m['advice'] as String?,
    );
  }
}

class EstrusDetailData {
  const EstrusDetailData({
    required this.livestockId,
    required this.livestockCode,
    required this.score,
    this.stepIncreasePercent,
    this.tempDelta,
    this.distanceDelta,
    this.timestamp,
    this.advice,
    this.trend7d = const [],
  });

  final String livestockId;
  final String livestockCode;
  final int score;
  final int? stepIncreasePercent;
  final double? tempDelta;
  final double? distanceDelta;
  final DateTime? timestamp;
  final String? advice;
  final List<EstrusTrendPoint> trend7d;

  factory EstrusDetailData.fromJson(Map<String, dynamic> m) {
    return EstrusDetailData(
      livestockId: (m['livestockId'] ?? '').toString(),
      livestockCode: (m['livestockCode'] ?? '') as String,
      score: m['score'] as int? ?? 0,
      stepIncreasePercent: m['stepIncreasePercent'] as int?,
      tempDelta: (m['tempDelta'] as num?)?.toDouble(),
      distanceDelta: (m['distanceDelta'] as num?)?.toDouble(),
      timestamp: m['timestamp'] != null ? DateTime.parse(m['timestamp'] as String) : null,
      advice: m['advice'] as String?,
      trend7d: (m['trend7d'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => EstrusTrendPoint(
                    score: (e['score'] as num?)?.toDouble() ?? 0.0,
                    timestamp: DateTime.parse(e['timestamp'] as String),
                  ))
              .toList() ??
          [],
    );
  }
}

class EpidemicData {
  const EpidemicData({
    required this.metrics,
    this.contacts = const [],
    this.riskLevel = 'Normal',
  });

  final HerdHealthMetrics metrics;
  final List<ContactTrace> contacts;
  final String riskLevel;

  factory EpidemicData.fromJson(Map<String, dynamic> m) {
    return EpidemicData(
      riskLevel: (m['riskLevel'] ?? 'Normal') as String,
      metrics: m['metrics'] != null
          ? HerdHealthMetrics(
              avgTemperature: (m['metrics']['avgTemperature'] as num?)?.toDouble() ?? 0.0,
              avgActivity: (m['metrics']['avgActivity'] as num?)?.toDouble() ?? 0.0,
              abnormalRate: (m['metrics']['abnormalRate'] as num?)?.toDouble() ?? 0.0,
              totalLivestock: m['metrics']['totalLivestock'] as int? ?? 0,
              abnormalCount: m['metrics']['abnormalCount'] as int? ?? 0,
            )
          : const HerdHealthMetrics(
              avgTemperature: 0.0, avgActivity: 0.0,
              abnormalRate: 0.0, totalLivestock: 0, abnormalCount: 0),
      contacts: (m['contacts'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => ContactTrace(
                    fromId: (e['fromId'] ?? '').toString(),
                    toId: (e['toId'] ?? '').toString(),
                    proximity: (e['proximity'] as num?)?.toDouble() ?? 0.0,
                    lastContact: e['lastContact'] != null
                        ? DateTime.parse(e['lastContact'] as String)
                        : DateTime.now(),
                  ))
              .toList() ??
          [],
    );
  }
}
