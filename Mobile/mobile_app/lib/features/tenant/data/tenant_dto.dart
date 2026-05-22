import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

class TenantDto {
  const TenantDto._();

  static Tenant? fromJson(Map<String, dynamic> json) {
    try {
      final status = TenantStatus.tryParse(json['status'] as String?);
      if (status == null) return null;
      final rawId = json['id'];
      return Tenant(
        id: rawId is int ? rawId.toString() : (rawId as String),
        name: json['name'] as String,
        status: status,
        licenseUsed: (json['licenseUsed'] as num?)?.toInt() ?? 0,
        licenseTotal: (json['licenseTotal'] as num?)?.toInt() ?? 0,
        contactName: json['contactName'] as String?,
        contactPhone: json['contactPhone'] as String?,
        contactEmail: json['contactEmail'] as String?,
        region: json['region'] as String?,
        remarks: json['remarks'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        lastUpdatedBy: json['lastUpdatedBy'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
