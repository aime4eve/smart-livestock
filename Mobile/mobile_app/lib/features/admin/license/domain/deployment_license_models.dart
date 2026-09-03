/// Domain models of the deployment-license admin module (NIX-184 T7a).
///
/// Field names mirror the backend DTOs under
/// `licensing/interfaces/admin/dto/` (LicenseModeResponse, EnrollmentResponse,
/// DeploymentLicenseStatusResponse, ImportLicenseResponse).
library;

/// Deployment mode reported by `GET /admin/deployment-license/mode`.
class LicenseModeInfo {
  const LicenseModeInfo({required this.mode, required this.pilotLicenseEnabled});

  final String mode;

  /// Whether the hosted pilot-license endpoint is switched on
  /// (`smartlivestock.pilot-license.enabled`).
  final bool pilotLicenseEnabled;

  bool get isHosted => mode.toUpperCase() == 'HOSTED';
  bool get isOnprem => mode.toUpperCase() == 'ONPREM';

  factory LicenseModeInfo.fromJson(Map<String, dynamic> json) {
    return LicenseModeInfo(
      mode: (json['mode'] ?? '').toString(),
      pilotLicenseEnabled: json['pilotLicenseEnabled'] as bool? ?? false,
    );
  }
}

/// Runtime state of the imported offline license (backend `runtimeStatus`).
enum LicenseRuntimeStatus { pendingActivation, valid, expired, suspended, unknown }

LicenseRuntimeStatus parseLicenseRuntimeStatus(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'PENDING_ACTIVATION':
      return LicenseRuntimeStatus.pendingActivation;
    case 'VALID':
      return LicenseRuntimeStatus.valid;
    case 'EXPIRED':
      return LicenseRuntimeStatus.expired;
    case 'SUSPENDED':
      return LicenseRuntimeStatus.suspended;
    default:
      return LicenseRuntimeStatus.unknown;
  }
}

/// Tenant entry for the license page dropdown (admin tenants API).
class DeploymentTenantOption {
  const DeploymentTenantOption({required this.id, required this.name, this.status});

  final int id;
  final String name;
  final String? status;

  factory DeploymentTenantOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return DeploymentTenantOption(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String?,
    );
  }
}

/// Enrollment info of `GET /admin/deployment-license/enrollment`.
class EnrollmentInfo {
  const EnrollmentInfo({
    required this.tenantId,
    required this.installationId,
    required this.fingerprintHash,
    required this.publicKeyId,
    required this.supportedPublicKeyIds,
    this.generatedAt,
  });

  final int tenantId;
  final String installationId;
  final String fingerprintHash;
  final String publicKeyId;
  final List<String> supportedPublicKeyIds;
  final String? generatedAt;

  factory EnrollmentInfo.fromJson(Map<String, dynamic> json) {
    return EnrollmentInfo(
      tenantId: (json['tenantId'] as num?)?.toInt() ?? 0,
      installationId: (json['installationId'] ?? '').toString(),
      fingerprintHash: (json['fingerprintHash'] ?? '').toString(),
      publicKeyId: (json['publicKeyId'] ?? '').toString(),
      supportedPublicKeyIds:
          (json['supportedPublicKeyIds'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      generatedAt: json['generatedAt'] as String?,
    );
  }
}

/// Full current-status view of `GET /admin/deployment-license/current`:
/// license summary, runtime state, subscription mapping, tamper-guard anchor
/// (`maxObservedAt`) and the most recent validation outcome.
class DeploymentLicenseStatus {
  const DeploymentLicenseStatus({
    this.tenantId,
    this.installationId,
    this.fingerprintHash,
    this.runtimeStatus = LicenseRuntimeStatus.unknown,
    this.licenseId,
    this.licenseType,
    this.tier,
    this.effectiveTier,
    this.issuedAt,
    this.expiresAt,
    this.acceptedAt,
    this.lastValidatedAt,
    this.lastResult,
    this.lastErrorCode,
    this.maxObservedAt,
    this.protectionReason,
    this.subscriptionStatus,
    this.subscriptionTrialEndsAt,
  });

  final int? tenantId;
  final String? installationId;
  final String? fingerprintHash;
  final LicenseRuntimeStatus runtimeStatus;
  final String? licenseId;
  final String? licenseType;
  final String? tier;
  final String? effectiveTier;
  final String? issuedAt;
  final String? expiresAt;
  final String? acceptedAt;
  final String? lastValidatedAt;
  final String? lastResult;
  final String? lastErrorCode;
  final String? maxObservedAt;
  final String? protectionReason;
  final String? subscriptionStatus;
  final String? subscriptionTrialEndsAt;

  /// True when the tenant should be guided to request a renewal from the
  /// vendor (design §12 renewal guidance).
  bool get needsRenewal =>
      runtimeStatus == LicenseRuntimeStatus.expired ||
      runtimeStatus == LicenseRuntimeStatus.suspended;

  factory DeploymentLicenseStatus.fromJson(Map<String, dynamic> json) {
    return DeploymentLicenseStatus(
      tenantId: (json['tenantId'] as num?)?.toInt(),
      installationId: json['installationId'] as String?,
      fingerprintHash: json['fingerprintHash'] as String?,
      runtimeStatus: parseLicenseRuntimeStatus(json['runtimeStatus'] as String?),
      licenseId: json['licenseId'] as String?,
      licenseType: json['licenseType'] as String?,
      tier: json['tier'] as String?,
      effectiveTier: json['effectiveTier'] as String?,
      issuedAt: json['issuedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      acceptedAt: json['acceptedAt'] as String?,
      lastValidatedAt: json['lastValidatedAt'] as String?,
      lastResult: json['lastResult'] as String?,
      lastErrorCode: json['lastErrorCode'] as String?,
      maxObservedAt: json['maxObservedAt'] as String?,
      protectionReason: json['protectionReason'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      subscriptionTrialEndsAt: json['subscriptionTrialEndsAt'] as String?,
    );
  }
}

/// Import result of `POST /admin/deployment-license` (multipart + confirm).
class ImportLicenseResult {
  const ImportLicenseResult({
    required this.tenantId,
    required this.runtimeStatus,
    this.licenseId,
    this.licenseType,
    this.tier,
    this.effectiveTier,
    this.expiresAt,
  });

  final int tenantId;
  final LicenseRuntimeStatus runtimeStatus;
  final String? licenseId;
  final String? licenseType;
  final String? tier;
  final String? effectiveTier;
  final String? expiresAt;

  factory ImportLicenseResult.fromJson(Map<String, dynamic> json) {
    return ImportLicenseResult(
      tenantId: (json['tenantId'] as num?)?.toInt() ?? 0,
      runtimeStatus: parseLicenseRuntimeStatus(json['runtimeStatus'] as String?),
      licenseId: json['licenseId'] as String?,
      licenseType: json['licenseType'] as String?,
      tier: json['tier'] as String?,
      effectiveTier: json['effectiveTier'] as String?,
      expiresAt: json['expiresAt'] as String?,
    );
  }
}
