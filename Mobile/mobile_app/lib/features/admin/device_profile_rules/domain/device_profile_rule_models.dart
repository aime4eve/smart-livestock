/// Domain models for the TB device profile allowlist (NIX-214).
library;

/// Local device types a TB device profile can map to (mirrors backend
/// DeviceType enum: EAR_TAG / TRACKER / CAPSULE).
enum RuleDeviceType { earTag, tracker, capsule }

extension RuleDeviceTypeX on RuleDeviceType {
  String get apiName {
    switch (this) {
      case RuleDeviceType.earTag:
        return 'EAR_TAG';
      case RuleDeviceType.tracker:
        return 'TRACKER';
      case RuleDeviceType.capsule:
        return 'CAPSULE';
    }
  }

  static RuleDeviceType fromApi(String value) {
    switch (value) {
      case 'EAR_TAG':
        return RuleDeviceType.earTag;
      case 'CAPSULE':
        return RuleDeviceType.capsule;
      case 'TRACKER':
      default:
        return RuleDeviceType.tracker;
    }
  }
}

class DeviceProfileRule {
  const DeviceProfileRule({
    required this.id,
    required this.profileName,
    required this.deviceType,
    required this.enabled,
    this.remark,
    this.updatedAt,
  });

  final int id;
  final String profileName;
  final RuleDeviceType deviceType;
  final bool enabled;
  final String? remark;
  final String? updatedAt;

  static DeviceProfileRule fromJson(Map<String, dynamic> m) {
    return DeviceProfileRule(
      id: (m['id'] as num).toInt(),
      profileName: (m['profileName'] ?? '').toString(),
      deviceType: RuleDeviceTypeX.fromApi((m['deviceType'] ?? '').toString()),
      enabled: m['enabled'] == true,
      remark: m['remark']?.toString(),
      updatedAt: m['updatedAt']?.toString(),
    );
  }
}

/// A device profile fetched live from ThingsBoard (for the form dropdown).
class TbProfile {
  const TbProfile({required this.id, required this.name});

  final String id;
  final String name;

  static TbProfile fromJson(Map<String, dynamic> m) {
    return TbProfile(id: (m['id'] ?? '').toString(), name: (m['name'] ?? '').toString());
  }
}
