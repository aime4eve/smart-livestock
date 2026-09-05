package com.smartlivestock.licensing.application;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;

import java.util.Locale;

/**
 * Guard for the trust-boundary deployment mode ({@code smartlivestock.license.mode},
 * design §2/§11, NIX-184 T5).
 * <p>
 * Companion of {@link PilotLicenseModeGuard} (which owns the HOSTED-only pilot
 * feature flag). This guard owns the HOSTED/ONPREM mutual exclusion:
 * <ul>
 *   <li>{@link #requireOnPrem()} — deployment-license management APIs are
 *       ONPREM-only and must never run against a HOSTED deployment.</li>
 *   <li>{@link #requireSelfServiceAllowed()} — in ONPREM mode the subscription
 *       is driven by the imported license file, so commerce self-service and
 *       manual subscription mutations are disabled (design §11 enforcement
 *       matrix).</li>
 * </ul>
 */
@Component
public class LicenseModeGuard {

    public static final String MODE_HOSTED = "HOSTED";
    public static final String MODE_ONPREM = "ONPREM";

    private final String mode;

    public LicenseModeGuard(@Value("${smartlivestock.license.mode:HOSTED}") String mode) {
        this.mode = mode != null ? mode.trim() : MODE_HOSTED;
    }

    /** True when the current deployment runs in ONPREM (customer-owned) mode. */
    public boolean isOnPrem() {
        return MODE_ONPREM.equalsIgnoreCase(mode);
    }

    /** Normalized mode name for reporting endpoints (always HOSTED or ONPREM). */
    public String modeName() {
        return mode.toUpperCase(Locale.ROOT);
    }

    /**
     * Throws {@link ErrorCode#AUTH_FORBIDDEN} unless the deployment is ONPREM.
     * Used by the deployment-license admin API (design §8, ONPREM-only).
     */
    public void requireOnPrem() {
        if (!isOnPrem()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "license.onpremOnly");
        }
    }

    /**
     * Throws {@link ErrorCode#LICENSE_REQUIRED} when running ONPREM, where
     * subscription lifecycle is license-driven and self-service/manual
     * mutation endpoints must not be reachable (design §11).
     */
    public void requireSelfServiceAllowed() {
        if (isOnPrem()) {
            throw new ApiException(ErrorCode.LICENSE_REQUIRED, "license.selfServiceDisabled");
        }
    }
}
