package com.smartlivestock.licensing.interfaces.admin.dto;

import com.smartlivestock.licensing.application.DeploymentLicenseApplicationService;

import java.util.List;

/**
 * Assembles application-layer results into the admin interface DTOs
 * (NIX-184 T5). Response shapes are the API contract referenced by task T9.
 */
public final class DeploymentLicenseResponseAssembler {

    private DeploymentLicenseResponseAssembler() {
        // static assembler
    }

    public static EnrollmentResponse toResponse(
            DeploymentLicenseApplicationService.EnrollmentInfo info) {
        return new EnrollmentResponse(info.tenantId(), info.installationId(),
                info.fingerprintHash(), info.publicKeyId(),
                info.supportedPublicKeyIds() != null
                        ? List.copyOf(info.supportedPublicKeyIds()) : List.of(),
                info.generatedAt());
    }

    public static ImportLicenseResponse toResponse(
            DeploymentLicenseApplicationService.ImportResult result) {
        return new ImportLicenseResponse(result.tenantId(), result.licenseId(),
                result.licenseType(), result.tier(), result.effectiveTier(),
                result.expiresAt(), result.runtimeStatus());
    }

    public static DeploymentLicenseStatusResponse toResponse(
            DeploymentLicenseApplicationService.DeploymentLicenseStatus status) {
        return new DeploymentLicenseStatusResponse(status.tenantId(), status.installationId(),
                status.fingerprintHash(), status.runtimeStatus(), status.licenseId(),
                status.licenseType(), status.tier(), status.effectiveTier(), status.issuedAt(),
                status.expiresAt(), status.acceptedAt(), status.lastValidatedAt(),
                status.lastResult(), status.lastErrorCode(), status.maxObservedAt(),
                status.protectionReason(), status.subscriptionStatus(),
                status.subscriptionTrialEndsAt());
    }
}
