import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/license/domain/deployment_license_models.dart';

/// API repository of the deployment-license admin module (NIX-184 T7a).
///
/// Endpoints (backend `DeploymentLicenseAdminController`, platform_admin only):
/// - GET  /admin/deployment-license/mode           (any mode)
/// - GET  /admin/deployment-license/enrollment     (ONPREM only)
/// - POST /admin/deployment-license                (ONPREM only, multipart)
/// - GET  /admin/deployment-license/current        (ONPREM only)
class DeploymentLicenseApiRepository {
  const DeploymentLicenseApiRepository();

  /// Deployment mode + pilot-license availability (usable in every mode).
  Future<LicenseModeInfo> loadMode() async {
    final data = await ApiClient.instance.get('/admin/deployment-license/mode');
    return LicenseModeInfo.fromJson(data);
  }

  /// Enrollment info (installation id + host fingerprint) of [tenantId].
  Future<EnrollmentInfo> loadEnrollment(int tenantId) async {
    final data = await ApiClient.instance
        .get('/admin/deployment-license/enrollment?tenantId=$tenantId');
    return EnrollmentInfo.fromJson(data);
  }

  /// Import an offline `.sllicense` envelope for [tenantId]. The multipart
  /// `file` field carries the UTF-8 envelope text and `confirm=true` asserts
  /// the operator's double confirmation (the import drives the subscription).
  Future<ImportLicenseResult> importLicense(
    int tenantId,
    List<int> bytes,
    String fileName,
  ) async {
    final data = await ApiClient.instance.uploadFile(
      '/admin/deployment-license?tenantId=$tenantId',
      bytes,
      fileName,
      fields: {'confirm': 'true'},
    );
    return ImportLicenseResult.fromJson(data);
  }

  /// Current license/runtime/subscription status of [tenantId].
  Future<DeploymentLicenseStatus> loadCurrent(int tenantId) async {
    final data = await ApiClient.instance
        .get('/admin/deployment-license/current?tenantId=$tenantId');
    return DeploymentLicenseStatus.fromJson(data);
  }

  /// Tenant list for the page dropdown (admin tenants API, feature_gate
  /// precedent). Page-sized generously: license administration is an
  /// operator-only surface with a small tenant count.
  Future<List<DeploymentTenantOption>> loadTenants() async {
    final data = await ApiClient.instance.get('/admin/tenants?page=1&pageSize=100');
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(DeploymentTenantOption.fromJson)
        .toList();
  }
}
