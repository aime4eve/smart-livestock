package com.smartlivestock.licensing.interfaces;

import com.smartlivestock.licensing.interfaces.dto.DeploymentInfoResponse;
import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.licensing.infrastructure.config.LicenseProperties;
import com.smartlivestock.shared.common.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public (unauthenticated) deployment descriptor for the login screen.
 * <p>
 * The login page renders before any authentication, so the license-mode
 * badge cannot use the platform-admin-only {@code /mode} endpoint. This
 * endpoint exposes the coarse deployment shape only:
 * <ul>
 *   <li>{@code mode} — HOSTED or ONPREM (a deployment characteristic that is
 *       observable from behavior anyway, not a secret)</li>
 *   <li>{@code runtimeStatus} — ONPREM only; the latest derived license state
 *       so a fresh on-premise install can show "not activated" guidance before
 *       anyone signs in. HOSTED always reports null.</li>
 * </ul>
 * No license payload, identifier, or fingerprint detail is exposed.
 * Contract note for T9: GET /api/v1/deployment-info, no auth.
 */
@RestController
@RequestMapping("/api/v1/deployment-info")
public class DeploymentInfoController {

    private final LicenseProperties licenseProperties;
    private final DeploymentLicenseStateRepository stateRepository;

    public DeploymentInfoController(LicenseProperties licenseProperties,
                                    DeploymentLicenseStateRepository stateRepository) {
        this.licenseProperties = licenseProperties;
        this.stateRepository = stateRepository;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<DeploymentInfoResponse>> deploymentInfo() {
        String runtimeStatus = null;
        if (licenseProperties.getMode() == LicenseProperties.LicenseMode.ONPREM) {
            runtimeStatus = stateRepository.findLatest()
                    .map(DeploymentLicenseState::getRuntimeStatus)
                    .map(Enum::name)
                    .orElse(null);
        }
        return ResponseEntity.ok(ApiResponse.ok(new DeploymentInfoResponse(
                licenseProperties.getMode().name(), runtimeStatus)));
    }
}
