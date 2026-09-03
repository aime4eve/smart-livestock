package com.smartlivestock.licensing.infrastructure.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * Configuration properties for the licensing context
 * ({@code smartlivestock.license.*}).
 * <p>
 * Hosted pilot-license toggles live under {@code smartlivestock.pilot-license.*}
 * and are owned by the application-layer configuration class.
 */
@Component
@ConfigurationProperties(prefix = "smartlivestock.license")
@Getter
@Setter
public class LicenseProperties {

    /** Trust-boundary deployment mode (design section 2). */
    public enum LicenseMode {
        /** We still operate the server (dev/test/internal/managed pilot). */
        HOSTED,
        /** Customer-owned on-premise server; offline license enforcement active. */
        ONPREM
    }

    /** Deployment mode; HOSTED keeps today's behavior (no host binding). */
    private LicenseMode mode = LicenseMode.HOSTED;

    /** Location of the trusted public key list. */
    private String publicKeyFile = "classpath:licensing/license-public-keys.json";

    /** Clock skew absorbed when checking issuedAt/expiresAt. */
    private Duration timeTolerance = Duration.ofMinutes(2);

    /** Periodic re-validation schedule for the deployment license state machine. */
    private String validationCron = "0 */5 * * * *";

    /** Host identity source hashed into the enrollment fingerprint. */
    private String hostFingerprintFile = "/etc/machine-id";
}
