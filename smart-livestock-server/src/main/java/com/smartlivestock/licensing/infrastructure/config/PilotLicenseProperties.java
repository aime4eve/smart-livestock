package com.smartlivestock.licensing.infrastructure.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Configuration for the hosted pilot license feature (design §7, NIX-184).
 * <p>
 * Bound from {@code smartlivestock.pilot-license.*}; the deployment mode
 * string itself lives under {@code smartlivestock.license.mode} and is read
 * by {@code PilotLicenseModeGuard} via {@code @Value}.
 */
@Component
@ConfigurationProperties(prefix = "smartlivestock.pilot-license")
@Getter
@Setter
public class PilotLicenseProperties {

    /** Pilot license granting is enabled by default in HOSTED deployments. */
    private boolean enabled = true;
}
