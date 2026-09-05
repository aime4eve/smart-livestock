package com.smartlivestock.licensing.application;

import com.smartlivestock.licensing.infrastructure.config.PilotLicenseProperties;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Guard enforcing that pilot license operations only run in HOSTED mode
 * with {@code smartlivestock.pilot-license.enabled=true} (design §7).
 * ONPREM deployments — or disabled pilots — are rejected with
 * {@link ErrorCode#AUTH_FORBIDDEN}.
 */
@Component
public class PilotLicenseModeGuard {

    public static final String MODE_HOSTED = "HOSTED";

    private final PilotLicenseProperties properties;
    private final String licenseMode;

    public PilotLicenseModeGuard(PilotLicenseProperties properties,
                                 @Value("${smartlivestock.license.mode:HOSTED}") String licenseMode) {
        this.properties = properties;
        this.licenseMode = licenseMode;
    }

    /**
     * Throws AUTH_FORBIDDEN unless the deployment is HOSTED and the pilot
     * license feature is enabled.
     */
    public void requireHostedPilotEnabled() {
        if (!properties.isEnabled() || !MODE_HOSTED.equalsIgnoreCase(licenseMode)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "license.pilot.modeForbidden");
        }
    }

    /** True when the current deployment may grant pilot licenses. */
    public boolean isHostedPilotEnabled() {
        return properties.isEnabled() && MODE_HOSTED.equalsIgnoreCase(licenseMode);
    }
}
