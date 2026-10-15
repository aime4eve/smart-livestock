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
    private final com.smartlivestock.identity.application.TenantZoneResolver tenantZoneResolver;

    public CloudPilotLicenseService(LicenseSubscriptionPort licenseSubscriptionPort,
                                    AuditLogRepository auditLogRepository,
                                    PilotLicenseModeGuard modeGuard,
                                    com.smartlivestock.identity.application.TenantZoneResolver tenantZoneResolver,
                                    @Value("${smartlivestock.trial.ends-at:}") String configuredTrialEndsAt) {
        this.licenseSubscriptionPort = licenseSubscriptionPort;
        this.auditLogRepository = auditLogRepository;
        this.modeGuard = modeGuard;
        this.tenantZoneResolver = tenantZoneResolver;
        this.configuredTrialEndsAt = ConfiguredTrialEnds.parse(configuredTrialEndsAt);
    }

    /**
     * Grant (or align) the pilot trial using the platform default deadline.
     */
    public PilotLicenseResult grantPilotLicense(Long targetTenantId) {
        return grantPilotLicense(targetTenantId, null);
    }

    /**
     * Grant (or align) the pilot trial for the target tenant.
     *
     * @param targetTenantId       tenant receiving the pilot license
     * @param requestedTrialEndsAt operator-specified deadline; when present it
     *                             overrides the platform default and is stored
     *                             on THIS tenant's subscription row (per-tenant
     *                             deadline, ruling follow-up 2026-10-12). Must
     *                             be in the future.
     * @return result describing the resulting subscription state
     * @throws ApiException AUTH_FORBIDDEN when not HOSTED/disabled,
     *                      VALIDATION_ERROR when the requested deadline is in
     *                      the past, STATE_CONFLICT when the current
     *                      subscription state forbids a pilot grant
     */
    public PilotLicenseResult grantPilotLicense(Long targetTenantId, Instant requestedTrialEndsAt) {
        return grantPilotLicense(targetTenantId, requestedTrialEndsAt, null);
    }

    /**
     * @param requestedLocalDate operator-specified LOCAL calendar date (e.g.
     *                           "2027-10-01"); converted to local midnight in
     *                           the tenant's own timezone and takes precedence
     *                           over {@code requestedTrialEndsAt}.
     */
    public PilotLicenseResult grantPilotLicense(Long targetTenantId, Instant requestedTrialEndsAt,
                                                java.time.LocalDate requestedLocalDate) {
        modeGuard.requireHostedPilotEnabled();
        Long operatorId = requireCurrentUserId();

        // Local date wins: converted through the tenant's own zone so
        // "2027-10-01" means Kenya midnight for a Kenya tenant — no manual
        // UTC conversion by the operator.
        Instant explicitEndsAt = requestedLocalDate != null
                ? requestedLocalDate.atStartOfDay(tenantZoneResolver.zoneForTenantStrict(targetTenantId)).toInstant()
                : requestedTrialEndsAt;

        String deadlineSource;
        final Instant pilotEndsAt;
        if (explicitEndsAt != null) {
            if (!explicitEndsAt.isAfter(Instant.now())) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "license.pilot.deadlineInPast");
            }
            pilotEndsAt = explicitEndsAt;
            deadlineSource = requestedLocalDate != null ? "REQUESTED_LOCAL_DATE" : "REQUESTED";
        } else {
            pilotEndsAt = configuredTrialEndsAt
                    .orElseGet(() -> Instant.now().plus(Duration.ofDays(PILOT_TRIAL_DAYS)));
            deadlineSource = configuredTrialEndsAt.isPresent() ? "CONFIGURED" : "ROLLING";
        }

        LicenseSubscriptionPort.LicenseSubscriptionSnapshot snapshot =
            licenseSubscriptionPort.findSubscription(targetTenantId).orElse(null);

        if (snapshot == null) {
            licenseSubscriptionPort.applyTrialLicense(targetTenantId, pilotEndsAt);
            audit(operatorId, targetTenantId, EVENT_PILOT_LICENSE_GRANT, Map.of(
                "tenantId", targetTenantId,
                "trialEndsAt", pilotEndsAt.toString(),
                "deadlineSource", deadlineSource,
                "previousStatus", "NONE"));
            return new PilotLicenseResult(targetTenantId, STATUS_TRIAL, pilotEndsAt);
        }

        // Ruling 2026-10-14: any non-ACTIVE subscription can be (re-)enrolled
        // into the hosted pilot — CANCELLED (e.g. after a tenant restore),
        // FREE (expired), SUSPENDED, EXPIRED, RENEWAL_FAILED, and lapsed
        // TRIALs. Only a paying (ACTIVE) subscription is protected from
        // being knocked back to trial.
        boolean wasTrial = STATUS_TRIAL.equals(snapshot.status());
        if (!wasTrial && "ACTIVE".equalsIgnoreCase(snapshot.status())) {
            audit(operatorId, targetTenantId, EVENT_PILOT_LICENSE_REJECTED, Map.of(
                "tenantId", targetTenantId,
                "currentStatus", snapshot.status() != null ? snapshot.status() : "UNKNOWN",
                "reason", "PILOT_STATE_CONFLICT"));
            throw new ApiException(ErrorCode.STATE_CONFLICT, "license.pilot.stateConflict",
                new Object[]{snapshot.status() != null ? snapshot.status() : "UNKNOWN"});
        }

        // Existing live TRIAL in rolling mode: extend-only (never shorten).
        // Fixed deadlines (explicit/platform) always converge the value.
        Instant effectiveEndsAt = deadlineSource.equals("ROLLING")
            && snapshot.trialEndsAt() != null
            && snapshot.trialEndsAt().isAfter(pilotEndsAt)
            ? snapshot.trialEndsAt() : pilotEndsAt;
        String previousStatus = snapshot.status() != null ? snapshot.status() : "NONE";
        licenseSubscriptionPort.applyTrialLicense(targetTenantId, effectiveEndsAt);
        audit(operatorId, targetTenantId, EVENT_PILOT_LICENSE_GRANT, Map.of(
            "tenantId", targetTenantId,
            "trialEndsAt", effectiveEndsAt.toString(),
            "deadlineSource", deadlineSource,
            "previousStatus", previousStatus));
        return new PilotLicenseResult(targetTenantId, STATUS_TRIAL, effectiveEndsAt);
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
