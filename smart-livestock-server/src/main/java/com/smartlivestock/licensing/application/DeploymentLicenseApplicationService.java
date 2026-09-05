package com.smartlivestock.licensing.application;

import com.smartlivestock.licensing.application.port.LicenseSubscriptionPort;
import com.smartlivestock.licensing.application.port.LicenseUsagePort;
import com.smartlivestock.licensing.domain.DeploymentInstallation;
import com.smartlivestock.licensing.domain.DeploymentLicense;
import com.smartlivestock.licensing.domain.DeploymentLicenseEvent;
import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.HostFingerprint;
import com.smartlivestock.licensing.domain.LicenseBinding;
import com.smartlivestock.licensing.domain.LicenseEnvelope;
import com.smartlivestock.licensing.domain.LicenseEventType;
import com.smartlivestock.licensing.domain.LicensePayload;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import com.smartlivestock.licensing.domain.LicenseType;
import com.smartlivestock.licensing.domain.LicenseValidationOutcome;
import com.smartlivestock.licensing.domain.LicenseValidationResult;
import com.smartlivestock.licensing.domain.LicenseValidator;
import com.smartlivestock.licensing.domain.repository.DeploymentInstallationRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseEventRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.licensing.infrastructure.HostFingerprintReader;
import com.smartlivestock.licensing.infrastructure.LicensePublicKeyRegistry;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.common.MessageResolver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Enrollment, offline license import and status reporting for on-premise
 * deployments (design §8/§9, NIX-184 T4).
 * <p>
 * Import pipeline (design §9): envelope structure → cryptographic verification
 * → binding triple (tenant + installation + live fingerprint) → time window →
 * quota pre-check → subscription mapping via {@link LicenseSubscriptionPort}.
 * A refused import never mutates the tenant's subscription or runtime state;
 * it only writes an audit event (plus a REJECTED record when the payload was
 * cryptographically verifiable).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DeploymentLicenseApplicationService {

    /** Feature keys checked against payload quotas before an import is accepted. */
    static final String[] QUOTA_FEATURE_KEYS = {
            "livestock_management", "fence_management", "worker_management", "device_management"
    };

    private static final String STATUS_TRIAL = "TRIAL";

    private final DeploymentInstallationRepository installationRepository;
    private final DeploymentLicenseRepository licenseRepository;
    private final DeploymentLicenseStateRepository stateRepository;
    private final DeploymentLicenseEventRepository eventRepository;
    private final LicenseValidator licenseValidator;
    private final HostFingerprintReader fingerprintReader;
    private final LicensePublicKeyRegistry publicKeyRegistry;
    private final LicenseSubscriptionPort subscriptionPort;
    private final LicenseUsagePort usagePort;
    private final MessageResolver messageResolver;

    // ── Enrollment (design §8 GET /enrollment) ───────────────────────

    /**
     * Return (or lazily create) the tenant's installation registration. The
     * installationId is generated once and stays stable; the fingerprint is
     * always read live from the host identity source.
     */
    @Transactional
    public EnrollmentInfo enroll(Long tenantId) {
        Instant now = Instant.now();
        HostFingerprint fingerprint = fingerprintReader.read();

        DeploymentInstallation installation = installationRepository.findByTenantId(tenantId)
                .orElse(null);
        if (installation == null) {
            installation = installationRepository.save(
                    DeploymentInstallation.create(tenantId, fingerprint, now));
        } else if (!fingerprint.getValue().equals(installation.getFingerprintHash())) {
            installation.refreshFingerprint(fingerprint, now);
            installationRepository.save(installation);
        }

        Set<String> supportedKeyIds = publicKeyRegistry.supportedKeyIds();
        String primaryKeyId = supportedKeyIds.stream().findFirst().orElse(null);
        return new EnrollmentInfo(tenantId, installation.getInstallationId().toString(),
                installation.getFingerprintHash(), primaryKeyId, supportedKeyIds, Instant.now());
    }

    // ── Import (design §8 POST, §9 authorization rules) ──────────────

    /**
     * Import an offline license file. {@code confirm=false} is refused up
     * front — the import mutates the tenant subscription, so an explicit
     * confirmation is mandatory.
     *
     * @throws ApiException VALIDATION_ERROR        when not confirmed / not enrolled
     * @throws ApiException LICENSE_*               when validation refuses the file
     * @throws ApiException STATE_CONFLICT          when the license type cannot map
     *                                              onto the current subscription state
     */
    @Transactional
    public ImportResult importLicense(Long tenantId, String rawEnvelope, boolean confirm) {
        if (!confirm) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "license.import.confirmRequired");
        }
        DeploymentInstallation installation = installationRepository.findByTenantId(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.VALIDATION_ERROR,
                        "license.import.notEnrolled"));
        HostFingerprint fingerprint = fingerprintReader.read();
        Long operatorId = currentUserIdOrNull();
        Instant now = Instant.now();

        LicenseEnvelope envelope;
        try {
            envelope = LicenseEnvelope.parse(rawEnvelope);
        } catch (Exception e) {
            writeEvent(null, tenantId, LicenseEventType.IMPORT_REJECTED,
                    null, ErrorCode.LICENSE_INVALID.name(),
                    Map.of("reason", safeMessage(e)), operatorId, now);
            throw new ApiException(ErrorCode.LICENSE_INVALID, "license.invalid");
        }

        LicenseBinding binding = new LicenseBinding(tenantId, installation.getInstallationId(),
                fingerprint);
        LicenseValidationResult result = licenseValidator.validate(envelope, binding, now);

        if (!result.isValid()) {
            ErrorCode errorCode = result.getErrorCode().orElse(ErrorCode.LICENSE_INVALID);
            persistRejected(result.getPayload(), tenantId, rawEnvelope, errorCode,
                    result.getMessage().orElse(null), operatorId, now);
            throw new ApiException(errorCode, rejectMessageKey(errorCode));
        }

        LicensePayload payload = result.getPayload();
        precheckQuotas(tenantId, payload, rawEnvelope, operatorId, now);
        mapSubscription(tenantId, payload, rawEnvelope, operatorId, now);

        // Accept: mark the previous CURRENT record REPLACED, store the new one.
        DeploymentLicense previous = licenseRepository.findCurrentByTenantId(tenantId).orElse(null);
        if (previous != null) {
            previous.markReplaced();
            licenseRepository.save(previous);
        }
        DeploymentLicense record = licenseRepository.save(DeploymentLicense.accept(
                payload, tenantId, rawEnvelope,
                previous != null ? previous.getLicenseId() : null, now));

        DeploymentLicenseState state = stateRepository.findByTenantId(tenantId)
                .orElseGet(() -> DeploymentLicenseState.initial(tenantId, now));
        state.advanceTime(now);
        state.transitionTo(LicenseRuntimeStatus.VALID, record.getLicenseId(), now, null, null);
        stateRepository.save(state);

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("licenseType", payload.getLicenseType().name());
        details.put("tier", payload.getTier());
        details.put("expiresAt", payload.getExpiresAt().toString());
        if (previous != null) {
            details.put("replacedLicenseId", previous.getLicenseId().toString());
        }
        writeEvent(record.getLicenseId(), tenantId, LicenseEventType.IMPORT_ACCEPTED,
                LicenseValidationOutcome.VALID.name(), null, details, operatorId, now);

        log.info("License {} imported for tenant {} (type={}, tier={})",
                payload.getLicenseId(), tenantId, payload.getLicenseType(), payload.getTier());
        return new ImportResult(tenantId, record.getLicenseId().toString(),
                payload.getLicenseType().name(), payload.getTier(), payload.getEffectiveTier(),
                payload.getExpiresAt(), LicenseRuntimeStatus.VALID.name());
    }

    // ── Status (design §8 GET /current) ──────────────────────────────

    /**
     * Current license, derived runtime state, subscription mapping, monotonic
     * time anchor and last validation outcome for the tenant.
     */
    @Transactional(readOnly = true)
    public DeploymentLicenseStatus currentStatus(Long tenantId) {
        DeploymentInstallation installation = installationRepository.findByTenantId(tenantId)
                .orElse(null);
        DeploymentLicense current = licenseRepository.findCurrentByTenantId(tenantId).orElse(null);
        DeploymentLicenseState state = stateRepository.findByTenantId(tenantId).orElse(null);

        LicenseSubscriptionPort.LicenseSubscriptionSnapshot subscription =
                subscriptionPort.findSubscription(tenantId).orElse(null);

        return new DeploymentLicenseStatus(
                tenantId,
                installation != null ? installation.getInstallationId().toString() : null,
                installation != null ? installation.getFingerprintHash() : null,
                state != null && state.getRuntimeStatus() != null
                        ? state.getRuntimeStatus().name() : LicenseRuntimeStatus.PENDING_ACTIVATION.name(),
                current != null ? current.getLicenseId().toString() : null,
                current != null && current.getLicenseType() != null
                        ? current.getLicenseType().name() : null,
                current != null ? current.getTier() : null,
                current != null ? current.getEffectiveTier() : null,
                current != null ? current.getIssuedAt() : null,
                current != null ? current.getExpiresAt() : null,
                current != null ? current.getAcceptedAt() : null,
                current != null ? current.getLastValidatedAt() : null,
                current != null && current.getLastResult() != null
                        ? current.getLastResult().name() : null,
                current != null ? current.getLastErrorCode() : null,
                state != null ? state.getMaxObservedAt() : null,
                state != null ? state.getProtectionReason() : null,
                subscription != null ? subscription.status() : null,
                subscription != null ? subscription.trialEndsAt() : null);
    }

    // ── Import helpers ───────────────────────────────────────────────

    /** Refuse the import when tenant usage exceeds a quota carried by the payload. */
    private void precheckQuotas(Long tenantId, LicensePayload payload, String rawEnvelope,
                                Long operatorId, Instant now) {
        Map<String, Integer> quotas = payload.getQuotas();
        for (String featureKey : QUOTA_FEATURE_KEYS) {
            Integer quota = quotas.get(featureKey);
            if (quota == null) {
                continue; // payload does not constrain this key → skip
            }
            int usage = usagePort.countCurrentUsage(tenantId, featureKey);
            if (usage > quota) {
                persistRejected(payload, tenantId, rawEnvelope, ErrorCode.LICENSE_QUOTA_EXCEEDED,
                        "usage " + usage + " exceeds quota " + quota + " for " + featureKey,
                        operatorId, now);
                throw new ApiException(ErrorCode.LICENSE_QUOTA_EXCEEDED,
                        "license.import.quotaExceeded",
                        new Object[]{featureKey, usage, quota});
            }
        }
    }

    /**
     * Drive the subscription through the port according to the design §9
     * mapping: TRIAL licenses only map onto "no subscription / active trial"
     * (a tenant whose trial already degraded to FREE must buy an ACTIVE
     * license); ACTIVE licenses map from TRIAL/FREE/ACTIVE.
     */
    private void mapSubscription(Long tenantId, LicensePayload payload, String rawEnvelope,
                                 Long operatorId, Instant now) {
        LicenseSubscriptionPort.LicenseSubscriptionSnapshot snapshot =
                subscriptionPort.findSubscription(tenantId).orElse(null);

        if (payload.getLicenseType() == LicenseType.TRIAL) {
            boolean allowed = snapshot == null
                    || (STATUS_TRIAL.equals(snapshot.status()) && snapshot.trialActive());
            if (!allowed) {
                persistRejected(payload, tenantId, rawEnvelope, ErrorCode.STATE_CONFLICT,
                        "trial license cannot map onto subscription status "
                                + (snapshot != null ? snapshot.status() : "NONE"), operatorId, now);
                throw new ApiException(ErrorCode.STATE_CONFLICT,
                        "license.import.trialDowngradeRejected");
            }
            subscriptionPort.applyTrialLicense(tenantId, payload.getExpiresAt());
            return;
        }

        // ACTIVE license: TRIAL / FREE / ACTIVE all map to ACTIVE (SUSPENDED
        // and other states are rejected by the commerce domain guard).
        subscriptionPort.applyActiveLicense(tenantId, payload.getTier(), payload.getExpiresAt());
    }

    /** Store a REJECTED record (payload verifiable only) plus the audit event. */
    private void persistRejected(LicensePayload payload, Long tenantId, String rawEnvelope,
                                 ErrorCode errorCode, String reason, Long operatorId, Instant now) {
        if (payload != null) {
            DeploymentLicense rejected = licenseRepository.save(DeploymentLicense.rejected(
                    payload, tenantId, rawEnvelope, errorCode.name(), now));
            writeEvent(rejected.getLicenseId(), tenantId, LicenseEventType.IMPORT_REJECTED,
                    LicenseValidationOutcome.INVALID.name(), errorCode.name(),
                    Map.of("reason", reason == null ? "" : reason), operatorId, now);
        } else {
            writeEvent(null, tenantId, LicenseEventType.IMPORT_REJECTED,
                    null, errorCode.name(),
                    Map.of("reason", reason == null ? "" : reason), operatorId, now);
        }
    }

    private void writeEvent(UUID licenseId, Long tenantId, LicenseEventType eventType,
                            String result, String errorCode, Map<String, Object> details,
                            Long operatorId, Instant now) {
        try {
            eventRepository.save(DeploymentLicenseEvent.of(licenseId, tenantId, eventType,
                    result, errorCode, details, operatorId, now));
        } catch (Exception e) {
            // Audit best-effort: never mask the business outcome.
            log.error("Failed to persist deployment license event {} for tenant {}",
                    eventType, tenantId, e);
        }
    }

    private String rejectMessageKey(ErrorCode errorCode) {
        return switch (errorCode) {
            case LICENSE_EXPIRED -> "license.import.expired";
            case LICENSE_BINDING_MISMATCH -> "license.bindingMismatch";
            default -> "license.invalid";
        };
    }

    private Long currentUserIdOrNull() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getPrincipal() instanceof Long userId ? userId : null;
    }

    private static String safeMessage(Exception e) {
        return e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
    }

    // ── Result records ───────────────────────────────────────────────

    /**
     * Enrollment information handed to the operator for license issuance
     * (design §8 response).
     */
    public record EnrollmentInfo(Long tenantId, String installationId, String fingerprintHash,
                                 String publicKeyId, Set<String> supportedPublicKeyIds,
                                 Instant generatedAt) {
    }

    /** Result of a successful license import. */
    public record ImportResult(Long tenantId, String licenseId, String licenseType, String tier,
                               String effectiveTier, Instant expiresAt, String runtimeStatus) {
    }

    /** Full status view for the current-status endpoint (design §8). */
    public record DeploymentLicenseStatus(Long tenantId, String installationId,
                                          String fingerprintHash, String runtimeStatus,
                                          String licenseId, String licenseType, String tier,
                                          String effectiveTier, Instant issuedAt, Instant expiresAt,
                                          Instant acceptedAt, Instant lastValidatedAt,
                                          String lastResult, String lastErrorCode,
                                          Instant maxObservedAt, String protectionReason,
                                          String subscriptionStatus, Instant subscriptionTrialEndsAt) {
    }
}
