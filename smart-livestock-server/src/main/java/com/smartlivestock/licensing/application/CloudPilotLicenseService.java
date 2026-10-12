package com.smartlivestock.licensing.application;

import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.licensing.application.port.LicenseSubscriptionPort;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ConfiguredTrialEnds;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Grants hosted pilot licenses to tenants (design §7, NIX-184).
 * <p>
 * Rules:
 * <ul>
 *   <li>HOSTED mode + {@code smartlivestock.pilot-license.enabled=true} only.</li>
 *   <li>No subscription: create TRIAL with the free-trial deadline.</li>
 *   <li>Active TRIAL: align to the same deadline.</li>
 *   <li>Any other state: reject with STATE_CONFLICT.</li>
 *   <li>Both grants and rejections are written to the audit log. The service
 *       is intentionally not {@code @Transactional} as a whole so the
 *       rejection audit entry survives the thrown exception; the port adapter
 *       commits its own transaction.</li>
 * </ul>
 * Free-trial deadline (ruling 2026-10-12): when
 * {@code smartlivestock.trial.ends-at} is configured, every grant ends at that
 * shared instant (Kenya campaign: 2027-10-01 00:00 EAT); an already-granted
 * later trial is converged back to it. When unconfigured, the legacy rolling
 * now+365d window applies.
 */
@Service
@Slf4j
public class CloudPilotLicenseService {

    /** Rolling fallback duration (legacy behavior, design §7: now + 365d). */
    static final long PILOT_TRIAL_DAYS = 365;

    public static final String EVENT_PILOT_LICENSE_GRANT = "PILOT_LICENSE_GRANT";
    public static final String EVENT_PILOT_LICENSE_REJECTED = "PILOT_LICENSE_REJECTED";

    private static final String STATUS_TRIAL = "TRIAL";

    private final LicenseSubscriptionPort licenseSubscriptionPort;
    private final AuditLogRepository auditLogRepository;
    private final PilotLicenseModeGuard modeGuard;
    private final Optional<Instant> configuredTrialEndsAt;

    public CloudPilotLicenseService(LicenseSubscriptionPort licenseSubscriptionPort,
                                    AuditLogRepository auditLogRepository,
                                    PilotLicenseModeGuard modeGuard,
                                    @Value("${smartlivestock.trial.ends-at:}") String configuredTrialEndsAt) {
        this.licenseSubscriptionPort = licenseSubscriptionPort;
        this.auditLogRepository = auditLogRepository;
        this.modeGuard = modeGuard;
        this.configuredTrialEndsAt = ConfiguredTrialEnds.parse(configuredTrialEndsAt);
    }

    /**
     * Grant (or align) the pilot trial for the target tenant.
     *
     * @param targetTenantId tenant receiving the pilot license
     * @return result describing the resulting subscription state
     * @throws ApiException AUTH_FORBIDDEN when not HOSTED/disabled,
     *                      STATE_CONFLICT when the current subscription state
     *                      forbids a pilot grant
     */
    public PilotLicenseResult grantPilotLicense(Long targetTenantId) {
        modeGuard.requireHostedPilotEnabled();
        Long operatorId = requireCurrentUserId();

        Instant pilotEndsAt = configuredTrialEndsAt
                .orElseGet(() -> Instant.now().plus(Duration.ofDays(PILOT_TRIAL_DAYS)));

        LicenseSubscriptionPort.LicenseSubscriptionSnapshot snapshot =
            licenseSubscriptionPort.findSubscription(targetTenantId).orElse(null);

        if (snapshot == null) {
            licenseSubscriptionPort.applyTrialLicense(targetTenantId, pilotEndsAt);
            audit(operatorId, targetTenantId, EVENT_PILOT_LICENSE_GRANT, Map.of(
                "tenantId", targetTenantId,
                "trialEndsAt", pilotEndsAt.toString(),
                "previousStatus", "NONE"));
            return new PilotLicenseResult(targetTenantId, STATUS_TRIAL, pilotEndsAt);
        }

        if (STATUS_TRIAL.equals(snapshot.status()) && snapshot.trialActive()) {
            // Fixed deadline wins even when the current trial ends later: the
            // ruling demands one shared campaign end for every free grant.
            Instant newTrialEndsAt = configuredTrialEndsAt
                .orElseGet(() -> snapshot.trialEndsAt() != null
                    && snapshot.trialEndsAt().isAfter(pilotEndsAt)
                    ? snapshot.trialEndsAt() : pilotEndsAt);
            licenseSubscriptionPort.applyTrialLicense(targetTenantId, newTrialEndsAt);
            audit(operatorId, targetTenantId, EVENT_PILOT_LICENSE_GRANT, Map.of(
                "tenantId", targetTenantId,
                "trialEndsAt", newTrialEndsAt.toString(),
                "previousStatus", STATUS_TRIAL));
            return new PilotLicenseResult(targetTenantId, STATUS_TRIAL, newTrialEndsAt);
        }

        audit(operatorId, targetTenantId, EVENT_PILOT_LICENSE_REJECTED, Map.of(
            "tenantId", targetTenantId,
            "currentStatus", snapshot.status() != null ? snapshot.status() : "UNKNOWN",
            "reason", "PILOT_STATE_CONFLICT"));
        throw new ApiException(ErrorCode.STATE_CONFLICT, "license.pilot.stateConflict",
            new Object[]{snapshot.status() != null ? snapshot.status() : "UNKNOWN"});
    }

    private void audit(Long operatorId, Long targetTenantId, String eventType, Map<String, Object> details) {
        try {
            Map<String, Object> auditDetails = new LinkedHashMap<>(details);
            auditLogRepository.save(new AuditLog(
                UUID.randomUUID().toString(),
                eventType,
                targetTenantId,
                operatorId,
                eventType,
                auditDetails,
                Instant.now(),
                null,
                "PLATFORM_ADMIN"));
        } catch (Exception e) {
            // Audit best-effort: never mask the business outcome.
            log.error("Failed to write pilot license audit event {} for tenant {}",
                eventType, targetTenantId, e);
        }
    }

    private Long requireCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof Long userId)) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "license.pilot.operatorMissing");
        }
        return userId;
    }

    /**
     * Result of a successful pilot license grant.
     *
     * @param tenantId     target tenant
     * @param status       resulting subscription status (always TRIAL)
     * @param trialEndsAt  resulting trial end timestamp
     */
    public record PilotLicenseResult(Long tenantId, String status, Instant trialEndsAt) {
    }
}
