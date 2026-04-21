import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

class TenantDto {
  const TenantDto._();

  static Tenant? fromJson(Map<String, dynamic> json) {
    try {
      final status = TenantStatus.tryParse(json['status'] as String?);
      if (status == null) return null;
      return Tenant(
        id: json['id'] as String,
        name: json['name'] as String,
        status: status,
        licenseUsed: (json['licenseUsed'] as num).toInt(),
        licenseTotal: (json['licenseTotal'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }
}
