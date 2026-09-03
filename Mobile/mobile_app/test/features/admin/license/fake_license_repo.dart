import 'package:hkt_livestock_agentic/features/admin/license/data/deployment_license_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/license/domain/deployment_license_models.dart';

/// Fake repository recording every call. Extends the concrete API repo so it
/// can be injected through [deploymentLicenseRepositoryProvider] overrides.
class FakeLicenseRepo extends DeploymentLicenseApiRepository {
  FakeLicenseRepo({
    this.mode = const LicenseModeInfo(mode: 'ONPREM', pilotLicenseEnabled: false),
  });

  LicenseModeInfo mode;
  List<DeploymentTenantOption> tenants = const [
    DeploymentTenantOption(id: 1, name: 'Acme', status: 'ACTIVE'),
    DeploymentTenantOption(id: 2, name: 'Beta', status: 'ACTIVE'),
  ];
  EnrollmentInfo enrollment = const EnrollmentInfo(
    tenantId: 1,
    installationId: 'inst-1',
    fingerprintHash: 'fp-1',
    publicKeyId: 'pk-1',
    supportedPublicKeyIds: ['pk-1', 'pk-2'],
    generatedAt: '2026-01-01T00:00:00Z',
  );
  DeploymentLicenseStatus current = const DeploymentLicenseStatus(
    tenantId: 1,
    installationId: 'inst-1',
    runtimeStatus: LicenseRuntimeStatus.valid,
    licenseId: 'lic-1',
    expiresAt: '2027-01-01T00:00:00Z',
  );
  ImportLicenseResult importResult = const ImportLicenseResult(
    tenantId: 1,
    licenseId: 'lic-9',
    runtimeStatus: LicenseRuntimeStatus.valid,
    expiresAt: '2027-06-01T00:00:00Z',
  );

  int modeCalls = 0;
  int tenantsCalls = 0;
  int enrollmentCalls = 0;
  int currentCalls = 0;
  int? lastEnrollmentTenantId;
  int? lastCurrentTenantId;
  ({int tenantId, List<int> bytes, String fileName})? lastImportCall;

  @override
  Future<LicenseModeInfo> loadMode() async {
    modeCalls++;
    return mode;
  }

  @override
  Future<List<DeploymentTenantOption>> loadTenants() async {
    tenantsCalls++;
    return tenants;
  }

  @override
  Future<EnrollmentInfo> loadEnrollment(int tenantId) async {
    enrollmentCalls++;
    lastEnrollmentTenantId = tenantId;
    return enrollment;
  }

  @override
  Future<DeploymentLicenseStatus> loadCurrent(int tenantId) async {
    currentCalls++;
    lastCurrentTenantId = tenantId;
    return current;
  }

  @override
  Future<ImportLicenseResult> importLicense(
    int tenantId,
    List<int> bytes,
    String fileName,
  ) async {
    lastImportCall = (tenantId: tenantId, bytes: bytes, fileName: fileName);
    return importResult;
  }
}
