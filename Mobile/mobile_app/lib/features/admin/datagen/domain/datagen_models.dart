class DatagenFarm {
  const DatagenFarm({
    required this.farmId,
    required this.farmName,
    required this.tenantId,
    required this.tenantName,
    required this.enabled,
    required this.selectedDeviceCount,
  });

  final int farmId;
  final String farmName;
  final int tenantId;
  final String tenantName;
  final bool enabled;
  final int selectedDeviceCount;

  factory DatagenFarm.fromJson(Map<String, dynamic> json) => DatagenFarm(
        farmId: _int(json['farmId']),
        farmName: json['farmName'] as String? ?? '',
        tenantId: _int(json['tenantId']),
        tenantName: json['tenantName'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        selectedDeviceCount: _int(json['selectedDeviceCount']),
      );
}

class DatagenScenario {
  const DatagenScenario({
    required this.id,
    required this.name,
    required this.type,
  });

  final int id;
  final String name;
  final String type;

  factory DatagenScenario.fromJson(Map<String, dynamic> json) => DatagenScenario(
        id: _int(json['id']),
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
      );
}

class DatagenRules {
  const DatagenRules({
    required this.trackerIntervalSeconds,
    required this.capsuleIntervalSeconds,
    required this.fenceExcursionProbability,
    required this.fenceExcursionMinMinutes,
    required this.fenceExcursionMaxMinutes,
    required this.healthEventProbability,
    required this.feverDurationMinMinutes,
    required this.feverDurationMaxMinutes,
    required this.motilityDurationMinMinutes,
    required this.motilityDurationMaxMinutes,
  });

  final int trackerIntervalSeconds;
  final int capsuleIntervalSeconds;
  final double fenceExcursionProbability;
  final int fenceExcursionMinMinutes;
  final int fenceExcursionMaxMinutes;
  final double healthEventProbability;
  final int feverDurationMinMinutes;
  final int feverDurationMaxMinutes;
  final int motilityDurationMinMinutes;
  final int motilityDurationMaxMinutes;

  factory DatagenRules.fromJson(Map<String, dynamic> json) => DatagenRules(
        trackerIntervalSeconds: _int(json['trackerIntervalSeconds']),
        capsuleIntervalSeconds: _int(json['capsuleIntervalSeconds']),
        fenceExcursionProbability: _double(
            json['fenceExcursionProbability']),
        fenceExcursionMinMinutes:
            _int(json['fenceExcursionMinMinutes']),
        fenceExcursionMaxMinutes:
            _int(json['fenceExcursionMaxMinutes']),
        healthEventProbability: _double(json['healthEventProbability']),
        feverDurationMinMinutes: _int(json['feverDurationMinMinutes']),
        feverDurationMaxMinutes: _int(json['feverDurationMaxMinutes']),
        motilityDurationMinMinutes:
            _int(json['motilityDurationMinMinutes']),
        motilityDurationMaxMinutes:
            _int(json['motilityDurationMaxMinutes']),
      );

  Map<String, dynamic> toJson() => {
        'trackerIntervalSeconds': trackerIntervalSeconds,
        'capsuleIntervalSeconds': capsuleIntervalSeconds,
        'fenceExcursionProbability': fenceExcursionProbability,
        'fenceExcursionMinMinutes': fenceExcursionMinMinutes,
        'fenceExcursionMaxMinutes': fenceExcursionMaxMinutes,
        'healthEventProbability': healthEventProbability,
        'feverDurationMinMinutes': feverDurationMinMinutes,
        'feverDurationMaxMinutes': feverDurationMaxMinutes,
        'motilityDurationMinMinutes': motilityDurationMinMinutes,
        'motilityDurationMaxMinutes': motilityDurationMaxMinutes,
      };
}

class DatagenDevice {
  const DatagenDevice({
    required this.deviceId,
    required this.deviceCode,
    required this.devEui,
    required this.deviceType,
    required this.livestockId,
    required this.livestockCode,
    required this.runtimeStatus,
    required this.selected,
    required this.eligible,
    required this.ineligibleReason,
    required this.lastGeneratedAt,
  });

  final int deviceId;
  final String deviceCode;
  final String devEui;
  final String deviceType;
  final int? livestockId;
  final String livestockCode;
  final String runtimeStatus;
  final bool selected;
  final bool eligible;
  final String? ineligibleReason;
  final DateTime? lastGeneratedAt;

  factory DatagenDevice.fromJson(Map<String, dynamic> json) => DatagenDevice(
        deviceId: _int(json['deviceId']),
        deviceCode: json['deviceCode'] as String? ?? '',
        devEui: json['devEui'] as String? ?? '',
        deviceType: json['deviceType'] as String? ?? '',
        livestockId: json['livestockId'] == null
            ? null
            : _int(json['livestockId']),
        livestockCode: json['livestockCode'] as String? ?? '',
        runtimeStatus: json['runtimeStatus'] as String? ?? '',
        selected: json['selected'] as bool? ?? false,
        eligible: json['eligible'] as bool? ?? false,
        ineligibleReason: json['ineligibleReason'] as String?,
        lastGeneratedAt: _date(json['lastGeneratedAt']),
      );
}

class DatagenStats {
  const DatagenStats({
    required this.statsTimeZone,
    required this.selectedTotal,
    required this.selectedTrackerCount,
    required this.selectedCapsuleCount,
    required this.todayTelemetryRows,
    required this.todayGpsRows,
    required this.todayHealthRows,
    required this.lastGeneratedAt,
  });

  final String statsTimeZone;
  final int selectedTotal;
  final int selectedTrackerCount;
  final int selectedCapsuleCount;
  final int todayTelemetryRows;
  final int todayGpsRows;
  final int todayHealthRows;
  final DateTime? lastGeneratedAt;

  factory DatagenStats.fromJson(Map<String, dynamic> json) => DatagenStats(
        statsTimeZone: json['statsTimeZone'] as String? ?? 'Asia/Shanghai',
        selectedTotal: _int(json['selectedTotal']),
        selectedTrackerCount: _int(json['selectedTrackerCount']),
        selectedCapsuleCount: _int(json['selectedCapsuleCount']),
        todayTelemetryRows: _int(json['todayTelemetryRows']),
        todayGpsRows: _int(json['todayGpsRows']),
        todayHealthRows: _int(json['todayHealthRows']),
        lastGeneratedAt: _date(json['lastGeneratedAt']),
      );
}

class DatagenOperation {
  const DatagenOperation({
    required this.id,
    required this.action,
    required this.operatorId,
    required this.operatorRole,
    required this.occurredAt,
    required this.summaryKey,
  });

  final int id;
  final String action;
  final int? operatorId;
  final String operatorRole;
  final DateTime? occurredAt;
  final String summaryKey;

  factory DatagenOperation.fromJson(Map<String, dynamic> json) =>
      DatagenOperation(
        id: _int(json['id']),
        action: json['action'] as String? ?? '',
        operatorId: json['operatorId'] == null ? null : _int(json['operatorId']),
        operatorRole: json['operatorRole'] as String? ?? '',
        occurredAt: _date(json['occurredAt']),
        summaryKey: json['summary'] as String? ?? '',
      );
}

class DatagenConsoleData {
  const DatagenConsoleData({
    required this.farm,
    required this.enabled,
    required this.scenario,
    required this.rules,
    required this.devices,
    required this.stats,
    required this.operations,
  });

  final DatagenFarm farm;
  final bool enabled;
  final DatagenScenario scenario;
  final DatagenRules rules;
  final List<DatagenDevice> devices;
  final DatagenStats stats;
  final List<DatagenOperation> operations;

  factory DatagenConsoleData.fromJson(Map<String, dynamic> json) =>
      DatagenConsoleData(
        farm: DatagenFarm.fromJson(_map(json['farm'])),
        enabled: json['enabled'] as bool? ?? false,
        scenario: DatagenScenario.fromJson(_map(json['scenario'])),
        rules: DatagenRules.fromJson(_map(json['rules'])),
        devices: (json['devices'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DatagenDevice.fromJson)
            .toList(),
        stats: DatagenStats.fromJson(_map(json['stats'])),
        operations: (json['operations'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DatagenOperation.fromJson)
            .toList(),
      );
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class DatagenClearResult {
  const DatagenClearResult({
    required this.telemetryRows,
    required this.gpsRows,
    required this.temperatureRows,
    required this.motilityRows,
    required this.activityRows,
    required this.estrusRows,
    required this.anomalyRows,
    required this.alertRows,
    required this.unattributableHealthRows,
    required this.unattributableAlertRows,
    required this.limitationKey,
  });

  final int telemetryRows;
  final int gpsRows;
  final int temperatureRows;
  final int motilityRows;
  final int activityRows;
  final int estrusRows;
  final int anomalyRows;
  final int alertRows;
  final int unattributableHealthRows;
  final int unattributableAlertRows;
  final String limitationKey;

  factory DatagenClearResult.fromJson(Map<String, dynamic> json) =>
      DatagenClearResult(
        telemetryRows: _int(json['telemetryRows']),
        gpsRows: _int(json['gpsRows']),
        temperatureRows: _int(json['temperatureRows']),
        motilityRows: _int(json['motilityRows']),
        activityRows: _int(json['activityRows']),
        estrusRows: _int(json['estrusRows']),
        anomalyRows: _int(json['anomalyRows']),
        alertRows: _int(json['alertRows']),
        unattributableHealthRows: _int(json['unattributableHealthRows']),
        unattributableAlertRows: _int(json['unattributableAlertRows']),
        limitationKey: json['limitationKey'] as String? ?? '',
      );

  int get totalDeleted => telemetryRows +
      gpsRows +
      temperatureRows +
      motilityRows +
      activityRows +
      estrusRows +
      anomalyRows +
      alertRows;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}
