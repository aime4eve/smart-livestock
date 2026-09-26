class SignalFreshness {
  static const fresh = 'FRESH';
  static const delayed = 'DELAYED';
  static const stale = 'STALE';
  static const missing = 'MISSING';
}

class HealthMetricSignal {
  const HealthMetricSignal({
    this.value,
    required this.unit,
    this.status = 'MISSING',
    this.recordedAt,
    this.ageSeconds,
    this.freshness = SignalFreshness.missing,
    this.source,
  });

  final double? value;
  final String unit;
  final String status;
  final DateTime? recordedAt;
  final int? ageSeconds;
  final String freshness;
  final String? source;

  static HealthMetricSignal missing(String unit) =>
      HealthMetricSignal(unit: unit);

  factory HealthMetricSignal.fromJson(Map<String, dynamic> json, String unit) {
    return HealthMetricSignal(
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? unit,
      status: json['status'] as String? ?? 'MISSING',
      recordedAt: _date(json['recordedAt']),
      ageSeconds: json['ageSeconds'] as int?,
      freshness: json['freshness'] as String? ?? SignalFreshness.missing,
      source: json['source'] as String?,
    );
  }
}

class HealthMetricsSignal {
  const HealthMetricsSignal({
    required this.rumenTemperature,
    required this.rumenMotility,
  });

  final HealthMetricSignal rumenTemperature;
  final HealthMetricSignal rumenMotility;

  factory HealthMetricsSignal.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'];
    final map = metrics is Map<String, dynamic> ? metrics : <String, dynamic>{};
    final temperature = map['rumenTemperature'];
    final motility = map['rumenMotility'];
    return HealthMetricsSignal(
      rumenTemperature: HealthMetricSignal.fromJson(
        temperature is Map<String, dynamic> ? temperature : {},
        'CELSIUS',
      ),
      rumenMotility: HealthMetricSignal.fromJson(
        motility is Map<String, dynamic> ? motility : {},
        'TIMES_PER_MINUTE',
      ),
    );
  }
}

class HealthSignal {
  const HealthSignal({
    this.status = 'NORMAL',
    this.activeAlertTypes = const [],
    HealthMetricsSignal? metrics,
  }) : metrics =
           metrics ??
           const HealthMetricsSignal(
             rumenTemperature: HealthMetricSignal(unit: 'CELSIUS'),
             rumenMotility: HealthMetricSignal(unit: 'TIMES_PER_MINUTE'),
           );

  final String status;
  final List<String> activeAlertTypes;
  final HealthMetricsSignal metrics;

  factory HealthSignal.fromJson(Map<String, dynamic> json) {
    return HealthSignal(
      status: json['status'] as String? ?? 'NORMAL',
      activeAlertTypes:
          (json['activeAlertTypes'] as List?)?.whereType<String>().toList() ??
          const [],
      metrics: HealthMetricsSignal.fromJson(json),
    );
  }
}

class AiSignal {
  const AiSignal({
    this.status = 'NONE',
    this.score,
    this.anomalyType,
    this.assessedAt,
  });

  final String status;
  final double? score;
  final String? anomalyType;
  final DateTime? assessedAt;

  factory AiSignal.fromJson(Map<String, dynamic> json) {
    return AiSignal(
      status: json['status'] as String? ?? 'NONE',
      score: (json['score'] as num?)?.toDouble(),
      anomalyType: json['anomalyType'] as String?,
      assessedAt: _date(json['assessedAt']),
    );
  }
}

class FenceSignal {
  const FenceSignal({this.status = 'NORMAL', this.activeAlertTypes = const []});

  final String status;
  final List<String> activeAlertTypes;

  factory FenceSignal.fromJson(Map<String, dynamic> json) {
    return FenceSignal(
      status: json['status'] as String? ?? 'NORMAL',
      activeAlertTypes:
          (json['activeAlertTypes'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }
}

class DeviceSignal {
  const DeviceSignal({
    this.status = 'NORMAL',
    this.faultTypes = const [],
    this.deviceCount = 0,
  });

  final String status;
  final List<String> faultTypes;
  final int deviceCount;

  factory DeviceSignal.fromJson(Map<String, dynamic> json) {
    return DeviceSignal(
      status: json['status'] as String? ?? 'NORMAL',
      faultTypes:
          (json['faultTypes'] as List?)?.whereType<String>().toList() ??
          const [],
      deviceCount: json['deviceCount'] as int? ?? 0,
    );
  }
}

class AlertSummarySignal {
  const AlertSummarySignal({this.activeCount = 0, this.unreadCount = 0});

  final int activeCount;
  final int unreadCount;

  factory AlertSummarySignal.fromJson(Map<String, dynamic> json) {
    return AlertSummarySignal(
      activeCount: json['activeCount'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}

class LivestockSignal {
  const LivestockSignal({
    required this.livestockId,
    required this.livestockCode,
    required this.revision,
    required this.health,
    required this.ai,
    required this.fence,
    required this.device,
    required this.alerts,
  });

  final String livestockId;
  final String livestockCode;
  final int revision;
  final HealthSignal health;
  final AiSignal ai;
  final FenceSignal fence;
  final DeviceSignal device;
  final AlertSummarySignal alerts;

  bool get hasHealthAlert =>
      health.status == 'WATCH' || health.status == 'CRITICAL';

  factory LivestockSignal.fromJson(Map<String, dynamic> json) {
    return LivestockSignal(
      livestockId: (json['livestockId'] ?? '').toString(),
      livestockCode: json['livestockCode'] as String? ?? '',
      revision: json['revision'] as int? ?? 0,
      health: HealthSignal.fromJson(
        json['health'] is Map<String, dynamic>
            ? json['health'] as Map<String, dynamic>
            : {},
      ),
      ai: AiSignal.fromJson(
        json['ai'] is Map<String, dynamic>
            ? json['ai'] as Map<String, dynamic>
            : {},
      ),
      fence: FenceSignal.fromJson(
        json['fence'] is Map<String, dynamic>
            ? json['fence'] as Map<String, dynamic>
            : {},
      ),
      device: DeviceSignal.fromJson(
        json['device'] is Map<String, dynamic>
            ? json['device'] as Map<String, dynamic>
            : {},
      ),
      alerts: AlertSummarySignal.fromJson(
        json['alerts'] is Map<String, dynamic>
            ? json['alerts'] as Map<String, dynamic>
            : {},
      ),
    );
  }
}

class PositionSignal {
  const PositionSignal({
    required this.livestockId,
    required this.revision,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.ageSeconds,
    required this.freshness,
    required this.source,
  });

  final String livestockId;
  final int revision;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final int ageSeconds;
  final String freshness;
  final String source;

  factory PositionSignal.fromJson(Map<String, dynamic> json) {
    return PositionSignal(
      livestockId: (json['livestockId'] ?? '').toString(),
      revision: json['revision'] as int? ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lng'] as num?)?.toDouble() ?? 0.0,
      recordedAt: _date(json['recordedAt']) ?? DateTime.now().toUtc(),
      ageSeconds: json['ageSeconds'] as int? ?? 0,
      freshness: json['freshness'] as String? ?? SignalFreshness.missing,
      source: json['source'] as String? ?? '',
    );
  }
}

class MapFenceSignal {
  const MapFenceSignal({
    required this.fenceId,
    required this.name,
    required this.revision,
    required this.status,
    required this.activeAlertTypes,
    required this.livestockCount,
    required this.geometry,
  });

  final String fenceId;
  final String name;
  final int revision;
  final String status;
  final List<String> activeAlertTypes;
  final int livestockCount;
  final List<List<double>> geometry;

  factory MapFenceSignal.fromJson(Map<String, dynamic> json) {
    final rawGeometry = json['geometry'] as List?;
    return MapFenceSignal(
      fenceId: (json['fenceId'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      revision: json['revision'] as int? ?? 0,
      status: json['status'] as String? ?? 'NORMAL',
      activeAlertTypes:
          (json['activeAlertTypes'] as List?)?.whereType<String>().toList() ??
          const [],
      livestockCount: json['livestockCount'] as int? ?? 0,
      geometry:
          rawGeometry
              ?.whereType<List>()
              .map(
                (point) => point
                    .whereType<num>()
                    .map((value) => value.toDouble())
                    .toList(),
              )
              .toList() ??
          const [],
    );
  }
}

DateTime? _date(Object? value) => value is String && value.isNotEmpty
    ? DateTime.tryParse(value)?.toLocal()
    : null;
