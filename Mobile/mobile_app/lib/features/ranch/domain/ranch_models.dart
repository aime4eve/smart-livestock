import 'package:latlong2/latlong.dart';

// ── Overall Stats ──────────────────────────────────────────

class RanchOverviewStats {
  const RanchOverviewStats({
    required this.totalLivestock,
    required this.healthyRate,
    required this.alertCount,
    required this.criticalCount,
    required this.deviceOnlineRate,
    required this.inFenceRate,
  });

  final int totalLivestock;
  final double? healthyRate;
  final int alertCount;
  final int criticalCount;
  final double deviceOnlineRate;
  final double? inFenceRate;

  factory RanchOverviewStats.fromJson(Map<String, dynamic> m) {
    return RanchOverviewStats(
      totalLivestock: m['totalLivestock'] as int? ?? 0,
      healthyRate: (m['healthyRate'] as num?)?.toDouble(),
      alertCount: m['alertCount'] as int? ?? 0,
      criticalCount: m['criticalCount'] as int? ?? 0,
      deviceOnlineRate: (m['deviceOnlineRate'] as num?)?.toDouble() ?? 0.0,
      inFenceRate: (m['inFenceRate'] as num?)?.toDouble(),
    );
  }
}

// ── Scene Summary ──────────────────────────────────────────

class RanchSceneSummaryFever {
  const RanchSceneSummaryFever({required this.abnormalCount, required this.criticalCount});
  final int abnormalCount;
  final int criticalCount;

  factory RanchSceneSummaryFever.fromJson(Map<String, dynamic>? m) {
    return RanchSceneSummaryFever(
      abnormalCount: m?['abnormalCount'] as int? ?? 0,
      criticalCount: m?['criticalCount'] as int? ?? 0,
    );
  }
}

class RanchSceneSummaryDigestive {
  const RanchSceneSummaryDigestive({required this.abnormalCount, required this.watchCount});
  final int abnormalCount;
  final int watchCount;

  factory RanchSceneSummaryDigestive.fromJson(Map<String, dynamic>? m) {
    return RanchSceneSummaryDigestive(
      abnormalCount: m?['abnormalCount'] as int? ?? 0,
      watchCount: m?['watchCount'] as int? ?? 0,
    );
  }
}

class RanchSceneSummaryEstrus {
  const RanchSceneSummaryEstrus({required this.highScoreCount});
  final int highScoreCount;

  factory RanchSceneSummaryEstrus.fromJson(Map<String, dynamic>? m) {
    return RanchSceneSummaryEstrus(
      highScoreCount: m?['highScoreCount'] as int? ?? 0,
    );
  }
}

class RanchSceneSummaryEpidemic {
  const RanchSceneSummaryEpidemic({required this.abnormalRate});
  final double abnormalRate;

  factory RanchSceneSummaryEpidemic.fromJson(Map<String, dynamic>? m) {
    return RanchSceneSummaryEpidemic(
      abnormalRate: (m?['abnormalRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RanchSceneSummary {
  const RanchSceneSummary({
    required this.fever,
    required this.digestive,
    required this.estrus,
    required this.epidemic,
  });

  final RanchSceneSummaryFever fever;
  final RanchSceneSummaryDigestive digestive;
  final RanchSceneSummaryEstrus estrus;
  final RanchSceneSummaryEpidemic epidemic;

  factory RanchSceneSummary.fromJson(Map<String, dynamic>? m) {
    return RanchSceneSummary(
      fever: RanchSceneSummaryFever.fromJson(m?['fever'] != null ? Map<String, dynamic>.from(m?['fever'] as Map) : null),
      digestive: RanchSceneSummaryDigestive.fromJson(m?['digestive'] != null ? Map<String, dynamic>.from(m?['digestive'] as Map) : null),
      estrus: RanchSceneSummaryEstrus.fromJson(m?['estrus'] != null ? Map<String, dynamic>.from(m?['estrus'] as Map) : null),
      epidemic: RanchSceneSummaryEpidemic.fromJson(m?['epidemic'] != null ? Map<String, dynamic>.from(m?['epidemic'] as Map) : null),
    );
  }
}

// ── Pending Task ───────────────────────────────────────────

class RanchPendingTask {
  const RanchPendingTask({
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

  factory RanchPendingTask.fromJson(Map<String, dynamic> m) {
    return RanchPendingTask(
      id: (m['id'] ?? '').toString(),
      title: m['title'] as String? ?? '',
      subtitle: m['subtitle'] as String? ?? '',
      routePath: m['routePath'] as String? ?? '',
      severity: m['severity'] as String? ?? 'INFO',
    );
  }
}

// ── Fence Data ─────────────────────────────────────────────

class RanchFenceData {
  const RanchFenceData({
    required this.id,
    required this.name,
    required this.active,
    required this.type,
    required this.colorValue,
    required this.points,
    required this.areaHectares,
    required this.livestockCount,
    required this.version,
  });

  final String id;
  final String name;
  final bool active;
  final String type;
  final int colorValue;
  final List<LatLng> points;
  final double areaHectares;
  final int livestockCount;
  final int version;

  factory RanchFenceData.fromJson(Map<String, dynamic> m) {
    final rawColor = m['color'] as String? ?? '#FF4C9A5F';
    final colorValue = _parseColor(rawColor);
    final rawPoints = (m['points'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((p) => LatLng(
                  (p['lat'] as num?)?.toDouble() ?? 0.0,
                  (p['lng'] as num?)?.toDouble() ?? 0.0,
                ))
            .toList() ??
        [];
    return RanchFenceData(
      id: (m['id'] ?? '').toString(),
      name: m['name'] as String? ?? '',
      active: m['active'] as bool? ?? true,
      type: m['type'] as String? ?? 'POLYGON',
      colorValue: colorValue,
      points: rawPoints,
      areaHectares: (m['areaHectares'] as num?)?.toDouble() ?? 0.0,
      livestockCount: m['livestockCount'] as int? ?? 0,
      version: m['version'] as int? ?? 1,
    );
  }
}

// ── Fence Zone Data ────────────────────────────────────────

class FenceZoneData {
  const FenceZoneData({
    required this.id,
    required this.fenceId,
    required this.name,
    required this.zoneType,
    required this.alertRadius,
    required this.severity,
  });

  final String id;
  final String fenceId;
  final String name;
  final String zoneType;
  final int alertRadius;
  final String severity;

  factory FenceZoneData.fromJson(Map<String, dynamic> m) {
    return FenceZoneData(
      id: (m['id'] ?? '').toString(),
      fenceId: (m['fenceId'] ?? '').toString(),
      name: m['name'] as String? ?? '',
      zoneType: m['zoneType'] as String? ?? '',
      alertRadius: m['alertRadius'] as int? ?? 20,
      severity: m['severity'] as String? ?? 'INFO',
    );
  }
}

// ── Livestock Marker ───────────────────────────────────────

class RanchLivestockMarker {
  const RanchLivestockMarker({
    required this.livestockId,
    required this.livestockCode,
    required this.latitude,
    required this.longitude,
    required this.healthStatus,
    required this.primaryAlert,
  });

  final String livestockId;
  final String livestockCode;
  final double latitude;
  final double longitude;
  final String healthStatus;
  final String primaryAlert;

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory RanchLivestockMarker.fromJson(Map<String, dynamic> m) {
    return RanchLivestockMarker(
      livestockId: (m['livestockId'] ?? '').toString(),
      livestockCode: (m['livestockCode'] ?? '') as String,
      latitude: (m['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (m['longitude'] as num?)?.toDouble() ?? 0.0,
      healthStatus: (m['healthStatus'] ?? 'NORMAL') as String,
      primaryAlert: (m['primaryAlert'] ?? '') as String,
    );
  }
}

// ── Alert Data ─────────────────────────────────────────────

class RanchAlertData {
  const RanchAlertData({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.message,
    this.livestockId,
    this.fenceId,
    this.occurredAt,
    this.read = false,
    this.distance,
    this.direction,
    this.resolvedType,
    this.resolvedAt,
  });

  final String id;
  final String type;
  final String severity;
  final String status;
  final String message;
  final String? livestockId;
  final String? fenceId;
  final String? occurredAt;
  final bool read;
  final double? distance;
  final String? direction;
  final String? resolvedType;
  final String? resolvedAt;

  factory RanchAlertData.fromJson(Map<String, dynamic> m) {
    return RanchAlertData(
      id: (m['id'] ?? '').toString(),
      type: (m['type'] ?? '') as String,
      severity: (m['severity'] ?? '') as String,
      status: (m['status'] ?? '') as String,
      message: (m['message'] ?? '') as String,
      livestockId: m['livestockId']?.toString(),
      fenceId: m['fenceId']?.toString(),
      occurredAt: m['occurredAt'] as String?,
      read: m['read'] as bool? ?? false,
      distance: (m['distance'] as num?)?.toDouble(),
      direction: m['direction'] as String?,
      resolvedType: m['resolvedType'] as String?,
      resolvedAt: m['resolvedAt'] as String?,
    );
  }

  RanchAlertData copyWith({
    bool? read,
    double? distance,
    String? direction,
    String? resolvedType,
    String? resolvedAt,
  }) {
    return RanchAlertData(
      id: id,
      type: type,
      severity: severity,
      status: status,
      message: message,
      livestockId: livestockId,
      fenceId: fenceId,
      occurredAt: occurredAt,
      read: read ?? this.read,
      distance: distance ?? this.distance,
      direction: direction ?? this.direction,
      resolvedType: resolvedType ?? this.resolvedType,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

// ── Ranch Overview Response ────────────────────────────────

class RanchOverview {
  const RanchOverview({
    required this.overallStats,
    required this.sceneSummary,
    required this.pendingTasks,
    required this.fences,
    required this.livestockMarkers,
    required this.alerts,
    required this.fenceAlertSummary,
    required this.healthAlertSummary,
    required this.fenceZones,
  });

  final RanchOverviewStats overallStats;
  final RanchSceneSummary sceneSummary;
  final List<RanchPendingTask> pendingTasks;
  final List<RanchFenceData> fences;
  final List<RanchLivestockMarker> livestockMarkers;
  final List<RanchAlertData> alerts;
  final Map<String, int> fenceAlertSummary;
  final Map<String, int> healthAlertSummary;
  final List<FenceZoneData> fenceZones;

  factory RanchOverview.fromJson(Map<String, dynamic> m) {
    return RanchOverview(
      overallStats: RanchOverviewStats.fromJson(
          m['overallStats'] != null ? Map<String, dynamic>.from(m['overallStats']) : <String, dynamic>{}),
      sceneSummary: RanchSceneSummary.fromJson(m['sceneSummary'] != null ? Map<String, dynamic>.from(m['sceneSummary'] as Map) : null),
      pendingTasks: (m['pendingTasks'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(RanchPendingTask.fromJson)
              .toList() ??
          [],
      fences: (m['fences'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(RanchFenceData.fromJson)
              .toList() ??
          [],
      livestockMarkers: (m['livestockMarkers'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(RanchLivestockMarker.fromJson)
              .toList() ??
          [],
      alerts: (m['alerts'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(RanchAlertData.fromJson)
              .toList() ??
          [],
      fenceAlertSummary: _parseIntMap(m['fenceAlertSummary']),
      healthAlertSummary: _parseIntMap(m['healthAlertSummary']),
      fenceZones: (m['fenceZones'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(FenceZoneData.fromJson)
              .toList() ??
          [],
    );
  }

  RanchOverview copyWith({
    RanchOverviewStats? overallStats,
    RanchSceneSummary? sceneSummary,
    List<RanchPendingTask>? pendingTasks,
    List<RanchFenceData>? fences,
    List<RanchLivestockMarker>? livestockMarkers,
    List<RanchAlertData>? alerts,
    Map<String, int>? fenceAlertSummary,
    Map<String, int>? healthAlertSummary,
    List<FenceZoneData>? fenceZones,
  }) {
    return RanchOverview(
      overallStats: overallStats ?? this.overallStats,
      sceneSummary: sceneSummary ?? this.sceneSummary,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      fences: fences ?? this.fences,
      livestockMarkers: livestockMarkers ?? this.livestockMarkers,
      alerts: alerts ?? this.alerts,
      fenceAlertSummary: fenceAlertSummary ?? this.fenceAlertSummary,
      healthAlertSummary: healthAlertSummary ?? this.healthAlertSummary,
      fenceZones: fenceZones ?? this.fenceZones,
    );
  }

  static Map<String, int> _parseIntMap(dynamic m) {
    if (m is Map<String, dynamic>) {
      return m.map((k, v) => MapEntry(k, v is int ? v : (v as num).toInt()));
    }
    return {};
  }
}

// ── Helpers ────────────────────────────────────────────────

int _parseColor(String color) {
  if (color.startsWith('#')) {
    final hex = color.replaceFirst('#', '');
    if (hex.length == 8) return int.parse('0x$hex');
    if (hex.length == 6) return int.parse('0xFF$hex');
  }
  if (color.startsWith('0x') || color.startsWith('0X')) {
    return int.parse(color);
  }
  return 0xFF4C9A5F;
}
