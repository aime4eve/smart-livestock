package com.smartlivestock.licensing.application;

import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import com.smartlivestock.licensing.domain.port.DeploymentAdminProvisioningPort;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * NIX-191 first-certificate window.
 * <p>
 * A fresh ONPREM install ships with zero accounts: nobody can log in to
 * enroll the machine or import the first certificate. While the deployment
 * has no active platform administrator and no accepted license yet, the
 * enrollment and first-import endpoints are reachable without
 * authentication. Safety is carried by the Ed25519 signature (only the
 * vendor issuing tool can produce an acceptable file), not by the session.
 * <p>
 * The window closes permanently once an administrator exists — every later
 * import (renewal) requires a logged-in platform admin.
 */
@Component
@RequiredArgsConstructor
public class AdminBootstrapWindow {

    private final LicenseModeGuard licenseModeGuard;
    private final DeploymentAdminProvisioningPort adminProvisioningPort;
    private final DeploymentLicenseStateRepository stateRepository;

    public boolean isOpen() {
        if (!"ONPREM".equalsIgnoreCase(licenseModeGuard.modeName())) {
            return false;
        }
        if (adminProvisioningPort.hasActivePlatformAdmin()) {
            return false;
        }
        return stateRepository.findLatest()
                .map(state -> state.getRuntimeStatus() != LicenseRuntimeStatus.VALID)
                .orElse(true);
    }
}
