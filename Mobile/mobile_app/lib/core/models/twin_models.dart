import 'package:smart_livestock_demo/core/models/view_state.dart';

class TwinPendingTask {
  const TwinPendingTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.routePath,
    required this.severity,
  });

  final String id;
  final String title;
  final String subtitle;
  final String routePath;
  final String severity;
}

class TwinOverviewViewData {
  const TwinOverviewViewData({
    required this.viewState,
    this.stats,
    this.sceneSummary,
    this.pendingTasks = const [],
    this.message,
  });

  final ViewState viewState;
  final TwinOverviewStats? stats;
  final TwinSceneSummary? sceneSummary;
  final List<TwinPendingTask> pendingTasks;
  final String? message;
}

class TwinOverviewStats {
  const TwinOverviewStats({
    required this.totalLivestock,
    required this.healthyRate,
    required this.alertCount,
    required this.criticalCount,
    required this.deviceOnlineRate,
    required this.livestockCaption,
    required this.alertCaption,
    required this.healthCaption,
    required this.deviceCaption,
    required this.healthTrend,
    required this.livestockTrend,
  });

  final int totalLivestock;
  final double healthyRate;
  final int alertCount;
  final int criticalCount;
  final double deviceOnlineRate;
  final String livestockCaption;
  final String alertCaption;
  final String healthCaption;
  final String deviceCaption;
  final String healthTrend;
  final String livestockTrend;
}

class TwinSceneSummary {
  const TwinSceneSummary({
    required this.fever,
    required this.digestive,
    required this.estrus,
    required this.epidemic,
  });

  final SceneSummaryFever fever;
  final SceneSummaryDigestive digestive;
  final SceneSummaryEstrus estrus;
  final SceneSummaryEpidemic epidemic;
}

class SceneSummaryFever {
  const SceneSummaryFever({
    required this.abnormalCount,
    required this.criticalCount,
  });

  final int abnormalCount;
  final int criticalCount;
}

class SceneSummaryDigestive {
  const SceneSummaryDigestive({
    required this.abnormalCount,
    required this.watchCount,
  });

  final int abnormalCount;
  final int watchCount;
}

class SceneSummaryEstrus {
  const SceneSummaryEstrus({
    required this.highScoreCount,
    required this.breedingAdvice,
  });

  final int highScoreCount;
  final bool breedingAdvice;
}

class SceneSummaryEpidemic {
  const SceneSummaryEpidemic({
    required this.status,
    required this.abnormalRate,
  });

  final String status;
  final double abnormalRate;
}

class FeverViewData {
  const FeverViewData({
    required this.viewState,
    this.items = const [],
    this.message,
  });

  final ViewState viewState;
  final List<TemperatureBaseline> items;
  final String? message;
}

class DigestiveViewData {
  const DigestiveViewData({
    required this.viewState,
    this.items = const [],
    this.message,
  });

  final ViewState viewState;
  final List<DigestiveHealth> items;
  final String? message;
}

class EstrusViewData {
  const EstrusViewData({
    required this.viewState,
    this.items = const [],
    this.message,
  });

  final ViewState viewState;
  final List<EstrusScore> items;
  final String? message;
}

class EpidemicViewData {
  const EpidemicViewData({
    required this.viewState,
    this.metrics,
    this.contacts = const [],
    this.message,
  });

  final ViewState viewState;
  final HerdHealthMetrics? metrics;
  final List<ContactTrace> contacts;
  final String? message;
}

class TemperatureRecord {
  const TemperatureRecord({
    required this.livestockId,
    required this.temperature,
    required this.timestamp,
  });

  final String livestockId;
  final double temperature;
  final DateTime timestamp;
}

class TemperatureBaseline {
  const TemperatureBaseline({
    required this.livestockId,
    required this.baselineTemp,
    required this.threshold,
    required this.recent72h,
    required this.status,
    this.conclusion,
  });

  final String livestockId;
  final double baselineTemp;
  final double threshold;
  final List<TemperatureRecord> recent72h;
  final String status;
  final String? conclusion;

  double get currentTemp =>
      recent72h.isEmpty ? baselineTemp : recent72h.last.temperature;

  double get delta => currentTemp - baselineTemp;
}

class MotilityRecord {
  const MotilityRecord({
    required this.livestockId,
    required this.frequency,
    required this.intensity,
    required this.timestamp,
  });

  final String livestockId;
  final double frequency;
  final double intensity;
  final DateTime timestamp;
}

class DigestiveHealth {
  const DigestiveHealth({
    required this.livestockId,
    required this.motilityBaseline,
    required this.status,
    this.advice,
    required this.recent24h,
  });

  final String livestockId;
  final double motilityBaseline;
  final String status;
  final String? advice;
  final List<MotilityRecord> recent24h;

  double get currentFrequency =>
      recent24h.isEmpty ? motilityBaseline : recent24h.last.frequency;
}

class EstrusTrendPoint {
  const EstrusTrendPoint({
    required this.score,
    required this.timestamp,
  });

  final double score;
  final DateTime timestamp;
}

class EstrusScore {
  const EstrusScore({
    required this.livestockId,
    required this.score,
    required this.stepIncreasePercent,
    required this.tempDelta,
    required this.distanceDelta,
    required this.timestamp,
    this.advice,
    this.trend7d = const [],
  });

  final String livestockId;
  final int score;
  final int stepIncreasePercent;
  final double tempDelta;
  final double distanceDelta;
  final DateTime timestamp;
  final String? advice;
  final List<EstrusTrendPoint> trend7d;
}

class HerdHealthMetrics {
  const HerdHealthMetrics({
    required this.avgTemperature,
    required this.avgActivity,
    required this.abnormalRate,
    required this.totalLivestock,
    required this.abnormalCount,
  });

  final double avgTemperature;
  final double avgActivity;
  final double abnormalRate;
  final int totalLivestock;
  final int abnormalCount;
}

class ContactTrace {
  const ContactTrace({
    required this.fromId,
    required this.toId,
    required this.lastContact,
    required this.proximity,
  });

  final String fromId;
  final String toId;
  final DateTime lastContact;
  final double proximity;
}
