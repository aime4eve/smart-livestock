export 'package:hkt_livestock_agentic/core/models/twin_models.dart';
import 'package:hkt_livestock_agentic/core/models/twin_models.dart';
import 'package:hkt_livestock_agentic/core/models/anomaly_models.dart';

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
     aiAnomalyCount: m['aiAnomalyCount'] as int? ?? 0,
     avgAiAnomalyScore:
         (m['avgAiAnomalyScore'] as num?)?.toDouble() ?? 0.0,
   );
  }

  static TwinSceneSummary _parseSceneSummary(Map<String, dynamic> m) {
    return TwinSceneSummary(
      fever: m['fever'] != null
          ? SceneSummaryFever(
              abnormalCount: m['fever']['abnormalCount'] as int? ?? 0,
              criticalCount: m['fever']['criticalCount'] as int? ?? 0,
              elevatedCount: m['fever']['elevatedCount'] as int? ?? 0,
              activeAlertCount: m['fever']['activeAlertCount'] as int? ?? 0,
            )
          : const SceneSummaryFever(abnormalCount: 0, criticalCount: 0),
      digestive: m['digestive'] != null
          ? SceneSummaryDigestive(
              abnormalCount: m['digestive']['abnormalCount'] as int? ?? 0,
              watchCount: m['digestive']['watchCount'] as int? ?? 0,
              activeAlertCount: m['digestive']['activeAlertCount'] as int? ?? 0,
            )
          : const SceneSummaryDigestive(abnormalCount: 0, watchCount: 0),
      estrus: m['estrus'] != null
          ? SceneSummaryEstrus(
              highScoreCount: m['estrus']['highScoreCount'] as int? ?? 0,
              breedingAdvice: m['estrus']['breedingAdvice'] as bool? ?? false,
              activeAlertCount: m['estrus']['activeAlertCount'] as int? ?? 0,
            )
          : const SceneSummaryEstrus(highScoreCount: 0, breedingAdvice: false),
      epidemic: m['epidemic'] != null
          ? SceneSummaryEpidemic(
              status: m['epidemic']['status'] as String? ?? 'Normal',
              abnormalRate: (m['epidemic']['abnormalRate'] as num?)?.toDouble() ?? 0.0,
              activeAlertCount: m['epidemic']['activeAlertCount'] as int? ?? 0,
            )
          : const SceneSummaryEpidemic(status: 'Normal', abnormalRate: 0.0),
      ai: m['ai'] != null
          ? SceneSummaryAi(
              anomalyCount: m['ai']['anomalyCount'] as int? ?? 0,
              highScoreCount: m['ai']['highScoreCount'] as int? ?? 0,
              avgScore: (m['ai']['avgScore'] as num?)?.toDouble() ?? 0.0,
              activeAlertCount: m['ai']['activeAlertCount'] as int? ?? 0,
            )
          : null,
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
    this.aiAnomaly,
  });

  final String livestockId;
  final String livestockCode;
  final double baselineTemp;
  final double threshold;
  final String status;
  final String? conclusion;
  final List<TemperatureRecord> recent72h;
  final AnomalyScoreData? aiAnomaly;

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
      aiAnomaly: m['aiAnomaly'] != null
          ? AnomalyScoreData.fromJson(m['aiAnomaly'])
          : null,
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
    this.aiAnomaly,
  });

  final String livestockId;
  final String livestockCode;
  final double motilityBaseline;
  final String status;
  final String? advice;
  final List<MotilityRecord> recent24h;
  final AnomalyScoreData? aiAnomaly;

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
                    frequency: (e['frequency'] as num?)?.toDouble(),
                    intensity: (e['intensity'] as num?)?.toDouble(),
                    rawCounter: (e['rawCounter'] as num?)?.toInt(),
                    counterDelta: (e['counterDelta'] as num?)?.toInt(),
                    source: e['source'] as String?,
                    timestamp: DateTime.parse(e['timestamp'] as String),
                  ))
              .toList() ??
          [],
      aiAnomaly: m['aiAnomaly'] != null
          ? AnomalyScoreData.fromJson(m['aiAnomaly'])
          : null,
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
    this.aiAnomaly,
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
  final AnomalyScoreData? aiAnomaly;

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
      aiAnomaly: m['aiAnomaly'] != null
          ? AnomalyScoreData.fromJson(m['aiAnomaly'])
          : null,
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

class EpidemicAnimalRef {
  const EpidemicAnimalRef({required this.livestockId, required this.livestockCode});
  final String livestockId;
  final String livestockCode;

  factory EpidemicAnimalRef.fromJson(Map<String, dynamic> m) => EpidemicAnimalRef(
        livestockId: (m['livestockId'] ?? '').toString(),
        livestockCode: m['livestockCode']?.toString() ?? '?',
      );
}

class EpidemicSourceData {
  const EpidemicSourceData({
    required this.livestockId,
    required this.livestockCode,
    this.diseaseType,
    this.markedAt,
    required this.status,
  });
  final String livestockId;
  final String livestockCode;
  final String? diseaseType;
  final DateTime? markedAt;
  final String status;

  factory EpidemicSourceData.fromJson(Map<String, dynamic> m) => EpidemicSourceData(
        livestockId: (m['livestockId'] ?? '').toString(),
        livestockCode: m['livestockCode']?.toString() ?? '?',
        diseaseType: m['diseaseType']?.toString(),
        markedAt: m['markedAt'] == null ? null : DateTime.parse(m['markedAt'] as String),
        status: m['status']?.toString() ?? 'UNMARKED',
      );
}

class EpidemicHerdMetricsData {
  const EpidemicHerdMetricsData({
    required this.avgTemperature,
    required this.abnormalRate,
    required this.totalLivestock,
    required this.abnormalCount,
    required this.riskLevel,
  });
  final double avgTemperature;
  final double abnormalRate;
  final int totalLivestock;
  final int abnormalCount;
  final String riskLevel;

  factory EpidemicHerdMetricsData.fromJson(Map<String, dynamic> m) => EpidemicHerdMetricsData(
        avgTemperature: (m['avgTemperature'] as num?)?.toDouble() ?? 0,
        abnormalRate: (m['abnormalRate'] as num?)?.toDouble() ?? 0,
        totalLivestock: (m['totalLivestock'] as num?)?.toInt() ?? 0,
        abnormalCount: (m['abnormalCount'] as num?)?.toInt() ?? 0,
        riskLevel: m['riskLevel']?.toString() ?? 'Normal',
      );
}

class EpidemicWorkbenchContext {
  const EpidemicWorkbenchContext({
    required this.source,
    required this.windowHours,
    required this.generatedAt,
    required this.syncedAt,
    required this.herdMetrics,
    this.lastContactAgeMinutes,
  });
  final EpidemicSourceData source;
  final int windowHours;
  final DateTime generatedAt;
  final DateTime syncedAt;
  final EpidemicHerdMetricsData herdMetrics;
  final int? lastContactAgeMinutes;

  factory EpidemicWorkbenchContext.fromJson(Map<String, dynamic> m) => EpidemicWorkbenchContext(
        source: EpidemicSourceData.fromJson(Map<String, dynamic>.from(m['source'] as Map)),
        windowHours: (m['windowHours'] as num?)?.toInt() ?? 72,
        generatedAt: m['generatedAt'] == null ? DateTime.now() : DateTime.parse(m['generatedAt'] as String),
        syncedAt: m['syncedAt'] == null ? DateTime.now() : DateTime.parse(m['syncedAt'] as String),
        herdMetrics: EpidemicHerdMetricsData.fromJson(
            Map<String, dynamic>.from((m['herdMetrics'] ?? const {}) as Map)),
        lastContactAgeMinutes: (m['lastContactAgeMinutes'] as num?)?.toInt(),
      );
}

class EpidemicTierSummary {
  const EpidemicTierSummary({required this.key, required this.rank, required this.count});
  final String key;
  final int rank;
  final int count;

  factory EpidemicTierSummary.fromJson(Map<String, dynamic> m) => EpidemicTierSummary(
        key: m['key']?.toString() ?? 'ARCHIVE',
        rank: (m['rank'] as num?)?.toInt() ?? 4,
        count: (m['count'] as num?)?.toInt() ?? 0,
      );
}

class EpidemicHealthSignal {
  const EpidemicHealthSignal({
    this.currentTemp,
    this.tempStatus,
    this.motilityStatus,
    required this.hasActiveHealthAlert,
    this.aiAnomalyScore,
  });
  final double? currentTemp;
  final String? tempStatus;
  final String? motilityStatus;
  final bool hasActiveHealthAlert;
  final double? aiAnomalyScore;

  factory EpidemicHealthSignal.fromJson(Map<String, dynamic> m) => EpidemicHealthSignal(
        currentTemp: (m['currentTemp'] as num?)?.toDouble(),
        tempStatus: m['tempStatus']?.toString(),
        motilityStatus: m['motilityStatus']?.toString(),
        hasActiveHealthAlert: m['hasActiveHealthAlert'] == true,
        aiAnomalyScore: (m['aiAnomalyScore'] as num?)?.toDouble(),
      );
}

class EpidemicLivestockItem {
  const EpidemicLivestockItem({
    required this.livestockId,
    required this.livestockCode,
    this.fenceName,
    required this.dispositionTier,
    required this.rank,
    required this.recommendedAction,
    required this.actionStatus,
    this.dispositionId,
    this.dueAt,
    required this.directSourceContact,
    required this.shortestDepth,
    required this.directContactCount,
    required this.maxRiskScore,
    required this.maxRiskLevel,
    this.lastContactAt,
    this.lastContactAgeMinutes,
    required this.health,
    required this.reasonCodes,
    required this.eventIds,
    required this.pathIds,
  });
  final String livestockId;
  final String livestockCode;
  final String? fenceName;
  final String dispositionTier;
  final int rank;
  final String recommendedAction;
  final String actionStatus;
  final int? dispositionId;
  final DateTime? dueAt;
  final bool directSourceContact;
  final int shortestDepth;
  final int directContactCount;
  final int maxRiskScore;
  final String maxRiskLevel;
  final DateTime? lastContactAt;
  final int? lastContactAgeMinutes;
  final EpidemicHealthSignal health;
  final List<String> reasonCodes;
  final List<int> eventIds;
  final List<String> pathIds;

  factory EpidemicLivestockItem.fromJson(Map<String, dynamic> m) => EpidemicLivestockItem(
        livestockId: (m['livestockId'] ?? '').toString(),
        livestockCode: m['livestockCode']?.toString() ?? '?',
        fenceName: m['fenceName']?.toString(),
        dispositionTier: m['dispositionTier']?.toString() ?? 'ARCHIVE',
        rank: (m['rank'] as num?)?.toInt() ?? 4,
        recommendedAction: m['recommendedAction']?.toString() ?? 'ARCHIVE_ONLY',
        actionStatus: m['actionStatus']?.toString() ?? 'PENDING',
        dispositionId: (m['dispositionId'] as num?)?.toInt(),
        dueAt: m['dueAt'] == null ? null : DateTime.parse(m['dueAt'] as String),
        directSourceContact: m['directSourceContact'] == true,
        shortestDepth: (m['shortestDepth'] as num?)?.toInt() ?? 99,
        directContactCount: (m['directContactCount'] as num?)?.toInt() ?? 0,
        maxRiskScore: (m['maxRiskScore'] as num?)?.toInt() ?? 0,
        maxRiskLevel: m['maxRiskLevel']?.toString() ?? 'LOW',
        lastContactAt: m['lastContactAt'] == null ? null : DateTime.parse(m['lastContactAt'] as String),
        lastContactAgeMinutes: (m['lastContactAgeMinutes'] as num?)?.toInt(),
        health: EpidemicHealthSignal.fromJson(
            Map<String, dynamic>.from((m['health'] ?? const {}) as Map)),
        reasonCodes: (m['reasonCodes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        eventIds: (m['eventIds'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [],
        pathIds: (m['pathIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class EpidemicEventData {
  const EpidemicEventData({
    required this.eventId,
    required this.from,
    required this.to,
    required this.proximityMeters,
    required this.durationMinutes,
    required this.lastContactAt,
    required this.hoursAgo,
    required this.riskScore,
    required this.riskLevel,
    required this.factorCodes,
  });
  final int eventId;
  final EpidemicAnimalRef from;
  final EpidemicAnimalRef to;
  final double proximityMeters;
  final int durationMinutes;
  final DateTime lastContactAt;
  final int hoursAgo;
  final int riskScore;
  final String riskLevel;
  final List<String> factorCodes;

  factory EpidemicEventData.fromJson(Map<String, dynamic> m) {
    final last = m['lastContactAt'] == null ? DateTime.now() : DateTime.parse(m['lastContactAt'] as String);
    return EpidemicEventData(
      eventId: (m['eventId'] as num?)?.toInt() ?? 0,
      from: EpidemicAnimalRef.fromJson(Map<String, dynamic>.from((m['from'] ?? const {}) as Map)),
      to: EpidemicAnimalRef.fromJson(Map<String, dynamic>.from((m['to'] ?? const {}) as Map)),
      proximityMeters: (m['proximityMeters'] as num?)?.toDouble() ?? 0,
      durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 0,
      lastContactAt: last,
      hoursAgo: (m['hoursAgo'] as num?)?.toInt() ?? 0,
      riskScore: (m['riskScore'] as num?)?.toInt() ?? 0,
      riskLevel: m['riskLevel']?.toString() ?? 'LOW',
      factorCodes: (m['factorCodes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class EpidemicGraphNode {
  const EpidemicGraphNode({
    required this.livestockId,
    required this.livestockCode,
    required this.kind,
    this.dispositionTier,
  });
  final String livestockId;
  final String livestockCode;
  final String kind;
  final String? dispositionTier;

  factory EpidemicGraphNode.fromJson(Map<String, dynamic> m) => EpidemicGraphNode(
        livestockId: (m['livestockId'] ?? '').toString(),
        livestockCode: m['livestockCode']?.toString() ?? '?',
        kind: m['kind']?.toString() ?? 'CONTACT',
        dispositionTier: m['dispositionTier']?.toString(),
      );
}

class EpidemicGraphEdge {
  const EpidemicGraphEdge({
    required this.edgeId,
    required this.fromLivestockId,
    required this.toLivestockId,
    required this.eventId,
    required this.depth,
    required this.riskScore,
    required this.riskLevel,
  });
  final String edgeId;
  final String fromLivestockId;
  final String toLivestockId;
  final int eventId;
  final int depth;
  final int riskScore;
  final String riskLevel;

  factory EpidemicGraphEdge.fromJson(Map<String, dynamic> m) => EpidemicGraphEdge(
        edgeId: m['edgeId']?.toString() ?? '',
        fromLivestockId: (m['fromLivestockId'] ?? '').toString(),
        toLivestockId: (m['toLivestockId'] ?? '').toString(),
        eventId: (m['eventId'] as num?)?.toInt() ?? 0,
        depth: (m['depth'] as num?)?.toInt() ?? 1,
        riskScore: (m['riskScore'] as num?)?.toInt() ?? 0,
        riskLevel: m['riskLevel']?.toString() ?? 'LOW',
      );
}

class EpidemicGraphPath {
  const EpidemicGraphPath({
    required this.pathId,
    required this.livestockIds,
    required this.edgeIds,
    required this.depth,
    required this.riskScore,
    required this.riskLevel,
  });
  final String pathId;
  final List<String> livestockIds;
  final List<String> edgeIds;
  final int depth;
  final int riskScore;
  final String riskLevel;

  factory EpidemicGraphPath.fromJson(Map<String, dynamic> m) => EpidemicGraphPath(
        pathId: m['pathId']?.toString() ?? '',
        livestockIds: (m['livestockIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        edgeIds: (m['edgeIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        depth: (m['depth'] as num?)?.toInt() ?? 0,
        riskScore: (m['riskScore'] as num?)?.toInt() ?? 0,
        riskLevel: m['riskLevel']?.toString() ?? 'LOW',
      );
}

class EpidemicNetworkData {
  const EpidemicNetworkData({
    required this.sourceLivestockId,
    required this.maxDepth,
    required this.nodes,
    required this.edges,
    required this.paths,
  });
  final String sourceLivestockId;
  final int maxDepth;
  final List<EpidemicGraphNode> nodes;
  final List<EpidemicGraphEdge> edges;
  final List<EpidemicGraphPath> paths;

  factory EpidemicNetworkData.fromJson(Map<String, dynamic> m) => EpidemicNetworkData(
        sourceLivestockId: (m['sourceLivestockId'] ?? '').toString(),
        maxDepth: (m['maxDepth'] as num?)?.toInt() ?? 2,
        nodes: (m['nodes'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(EpidemicGraphNode.fromJson)
                .toList() ??
            const [],
        edges: (m['edges'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(EpidemicGraphEdge.fromJson)
                .toList() ??
            const [],
        paths: (m['paths'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(EpidemicGraphPath.fromJson)
                .toList() ??
            const [],
      );
}

class EpidemicWorkbenchData {
  const EpidemicWorkbenchData({
    required this.context,
    required this.tiers,
    required this.livestock,
    required this.events,
    required this.network,
  });
  final EpidemicWorkbenchContext context;
  final List<EpidemicTierSummary> tiers;
  final List<EpidemicLivestockItem> livestock;
  final List<EpidemicEventData> events;
  final EpidemicNetworkData network;

  factory EpidemicWorkbenchData.fromJson(Map<String, dynamic> m) => EpidemicWorkbenchData(
        context: EpidemicWorkbenchContext.fromJson(
            Map<String, dynamic>.from((m['context'] ?? const {}) as Map)),
        tiers: (m['tiers'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(EpidemicTierSummary.fromJson)
                .toList() ??
            const [],
        livestock: (m['livestock'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(EpidemicLivestockItem.fromJson)
                .toList() ??
            const [],
        events: (m['events'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(EpidemicEventData.fromJson)
                .toList() ??
            const [],
        network: EpidemicNetworkData.fromJson(
            Map<String, dynamic>.from((m['network'] ?? const {}) as Map)),
      );
}

// ── Health Detail Chart Models (subscription-gated) ───────────

class DailyFeverHour {
  const DailyFeverHour({required this.date, required this.hours});
  final String date;
  final double hours;

  factory DailyFeverHour.fromJson(Map<String, dynamic> m) {
    return DailyFeverHour(
      date: m['date'] as String? ?? '',
      hours: (m['hours'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class IntensityCell {
  const IntensityCell({
    required this.hour,
    required this.intensity,
    required this.abnormal,
  });
  final int hour;
  final double intensity;
  final bool abnormal;

  factory IntensityCell.fromJson(Map<String, dynamic> m) {
    return IntensityCell(
      hour: m['hour'] as int? ?? 0,
      intensity: (m['intensity'] as num?)?.toDouble() ?? 0,
      abnormal: m['abnormal'] as bool? ?? false,
    );
  }
}

class ContactNode {
  const ContactNode({
    required this.livestockId,
    required this.livestockCode,
    required this.proximityMeters,
    required this.contactDurationMinutes,
    required this.lastContactAt,
    required this.hoursAgo,
    required this.timeScore,
    required this.distanceScore,
    required this.durationScore,
    required this.totalRiskScore,
    required this.riskLevel,
  });
  final String livestockId;
  final String livestockCode;
  final double proximityMeters;
  final int contactDurationMinutes;
  final DateTime lastContactAt;
  final int hoursAgo;
  final int timeScore;
  final int distanceScore;
  final int durationScore;
  final int totalRiskScore;
  final String riskLevel;

  factory ContactNode.fromJson(Map<String, dynamic> m) {
    return ContactNode(
      livestockId: (m['livestockId'] ?? '').toString(),
      livestockCode: m['livestockCode'] as String? ?? '?',
      proximityMeters: (m['proximityMeters'] as num?)?.toDouble() ?? 0,
      contactDurationMinutes: m['contactDurationMinutes'] as int? ?? 0,
      lastContactAt: m['lastContactAt'] != null
          ? DateTime.parse(m['lastContactAt'] as String)
          : DateTime.now(),
      hoursAgo: m['hoursAgo'] as int? ?? 0,
      timeScore: m['timeScore'] as int? ?? 0,
      distanceScore: m['distanceScore'] as int? ?? 0,
      durationScore: m['durationScore'] as int? ?? 0,
      totalRiskScore: m['totalRiskScore'] as int? ?? 0,
      riskLevel: m['riskLevel'] as String? ?? 'LOW',
    );
  }
}

class ContactNetworkResponse {
  const ContactNetworkResponse({
    required this.sourceLivestockId,
    required this.sourceLivestockCode,
    this.diseaseType,
    this.markedAt,
    required this.contacts,
  });
  final String sourceLivestockId;
  final String sourceLivestockCode;
  final String? diseaseType;
  final DateTime? markedAt;
  final List<ContactNode> contacts;

  factory ContactNetworkResponse.fromJson(Map<String, dynamic> m) {
    return ContactNetworkResponse(
      sourceLivestockId: (m['sourceLivestockId'] ?? '').toString(),
      sourceLivestockCode: m['sourceLivestockCode'] as String? ?? '?',
      diseaseType: m['diseaseType'] as String?,
      markedAt: m['markedAt'] != null
          ? DateTime.parse(m['markedAt'] as String)
          : null,
      contacts: (m['contacts'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ContactNode.fromJson)
              .toList() ??
          [],
    );
  }
}
