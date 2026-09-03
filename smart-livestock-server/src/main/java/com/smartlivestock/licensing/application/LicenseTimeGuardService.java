package com.smartlivestock.licensing.application;

import com.smartlivestock.licensing.application.port.LicenseSubscriptionPort;
import com.smartlivestock.licensing.domain.DeploymentInstallation;
import com.smartlivestock.licensing.domain.DeploymentLicense;
import com.smartlivestock.licensing.domain.DeploymentLicenseEvent;
import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.HostFingerprint;
import com.smartlivestock.licensing.domain.LicenseBinding;
import com.smartlivestock.licensing.domain.LicenseEnvelope;
import com.smartlivestock.licensing.domain.LicenseEventType;
import com.smartlivestock.licensing.domain.LicenseType;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import com.smartlivestock.licensing.domain.LicenseValidationOutcome;
import com.smartlivestock.licensing.domain.LicensePayload;
import com.smartlivestock.licensing.domain.LicenseValidationResult;
import com.smartlivestock.licensing.domain.LicenseValidator;
import com.smartlivestock.licensing.domain.repository.DeploymentInstallationRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseEventRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.licensing.infrastructure.HostFingerprintReader;
import com.smartlivestock.licensing.infrastructure.config.LicenseProperties;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.UUID;
import java.util.Map;
import java.util.Optional;

/**
 * Periodic re-validation state machine for on-premise deployment licenses
 * (design §9, NIX-184 T4b).
 * <p>
 * Every run:
 * <ol>
 *   <li>advances the monotonic {@code maxObservedAt} anchor;</li>
 *   <li>suspends the tenant when the clock rolled back beyond tolerance
 *       (SUSPENDED / LICENSE_TIME_ROLLBACK);</li>
 *   <li>otherwise re-derives the runtime state from the stored raw license of
 *       the CURRENT record — full pipeline including signature — so manual DB
 *       edits self-heal: EXPIRED → downgrade, missing/REPLACED current record
 *       → PENDING_ACTIVATION, valid license → recover to VALID.</li>
 * </ol>
 * Every run writes one {@code deployment_license_events} row (VALIDATION_*).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LicenseTimeGuardService {

    private final DeploymentInstallationRepository installationRepository;
    private final DeploymentLicenseRepository licenseRepository;
    private final DeploymentLicenseStateRepository stateRepository;
    private final DeploymentLicenseEventRepository eventRepository;
    private final LicenseValidator licenseValidator;
    private final HostFingerprintReader fingerprintReader;
    private final LicenseSubscriptionPort subscriptionPort;
    private final LicenseProperties licenseProperties;

    /**
     * Validate one tenant and return the derived runtime status, or
     * {@code empty} when the tenant has no installation yet.
     */
    @Transactional
    public Optional<LicenseRuntimeStatus> validateTenant(Long tenantId) {
        Optional<DeploymentInstallation> installationOpt =
                installationRepository.findByTenantId(tenantId);
        if (installationOpt.isEmpty()) {
            return Optional.empty();
        }
        DeploymentInstallation installation = installationOpt.get();
        Instant now = Instant.now();

        DeploymentLicenseState state = stateRepository.findByTenantId(tenantId)
                .orElseGet(() -> DeploymentLicenseState.initial(tenantId, now));
        LicenseRuntimeStatus previousStatus = state.getRuntimeStatus();

        // Step 2: monotonic time anchor.
        state.advanceTime(now);

        // Step 3: rollback protection.
        if (state.isTimeRollback(now, licenseProperties.getTimeTolerance())) {
            return suspendForRollback(tenantId, state, now);
        }

        // Steps 4-7: re-derive from the stored raw license.
        Optional<DeploymentLicense> currentOpt = licenseRepository.findCurrentByTenantId(tenantId);
        if (currentOpt.isEmpty()) {
            return markPendingActivation(tenantId, state, now);
        }

        DeploymentLicense current = currentOpt.get();
        LicenseValidationResult result = validateRaw(current, installation, tenantId, now);
        if (!result.isValid()) {
            // The verifier reports expiry as a validation failure; the state
            // machine maps it to EXPIRED (downgrade), not SUSPENDED.
            if (result.getErrorCode().orElse(null) == ErrorCode.LICENSE_EXPIRED) {
                return applyExpiredValidation(tenantId, state, current, result, now);
            }
            return applyFailedValidation(tenantId, state, current, result, now);
        }
        return applySuccessfulValidation(tenantId, state, current, result.getPayload(),
                previousStatus, now);
    }

    // ── State transitions ────────────────────────────────────────────

    private Optional<LicenseRuntimeStatus> suspendForRollback(Long tenantId,
                                                              DeploymentLicenseState state,
                                                              Instant now) {
        state.transitionTo(LicenseRuntimeStatus.SUSPENDED, state.getCurrentLicenseId(), now,
                ErrorCode.LICENSE_TIME_ROLLBACK.name(),
                DeploymentLicenseState.PROTECTION_TIME_ROLLBACK);
        stateRepository.save(state);
        safeSuspend(tenantId, "license time rollback detected");
        writeEvent(state.getCurrentLicenseId(), tenantId, LicenseEventType.VALIDATION_SUSPENDED,
                null, ErrorCode.LICENSE_TIME_ROLLBACK.name(),
                Map.of("maxObservedAt", String.valueOf(state.getMaxObservedAt())), null, now);
        log.warn("License suspended for tenant {}: system time rollback detected", tenantId);
        return Optional.of(LicenseRuntimeStatus.SUSPENDED);
    }

    private Optional<LicenseRuntimeStatus> markPendingActivation(Long tenantId,
                                                                 DeploymentLicenseState state,
                                                                 Instant now) {
        state.transitionTo(LicenseRuntimeStatus.PENDING_ACTIVATION, null, now,
                ErrorCode.LICENSE_REQUIRED.name(), null);
        stateRepository.save(state);
        writeEvent(null, tenantId, LicenseEventType.VALIDATION_FAILED, null,
                ErrorCode.LICENSE_REQUIRED.name(),
                Map.of("reason", "no current license record"), null, now);
        return Optional.of(LicenseRuntimeStatus.PENDING_ACTIVATION);
    }

    private Optional<LicenseRuntimeStatus> applyFailedValidation(Long tenantId,
                                                                 DeploymentLicenseState state,
                                                                 DeploymentLicense current,
                                                                 LicenseValidationResult result,
                                                                 Instant now) {
        var errorCode = result.getErrorCode()
                .orElse(ErrorCode.LICENSE_INVALID);
        // A broken signature or a moved host is a protective hold (design §9:
        // only a validly signed, correctly bound, in-time import recovers).
        String protection = errorCode == ErrorCode.LICENSE_BINDING_MISMATCH
                ? DeploymentLicenseState.PROTECTION_BINDING_MISMATCH
                : DeploymentLicenseState.PROTECTION_LICENSE_INVALID;
        state.transitionTo(LicenseRuntimeStatus.SUSPENDED, current.getLicenseId(), now,
                errorCode.name(), protection);
        stateRepository.save(state);
        current.markValidated(now, outcomeFor(errorCode), errorCode.name());
        licenseRepository.save(current);
        safeSuspend(tenantId, "license validation failed: " + errorCode);
        writeEvent(current.getLicenseId(), tenantId, LicenseEventType.VALIDATION_SUSPENDED,
                outcomeFor(errorCode).name(), errorCode.name(),
                Map.of("reason", result.getMessage().orElse("")), null, now);
        log.warn("License suspended for tenant {}: validation failed ({})", tenantId, errorCode);
        return Optional.of(LicenseRuntimeStatus.SUSPENDED);
    }

    /**
     * Runtime EXPIRED (design §9 mapping): degrade the subscription to
     * FREE/BASIC while keeping the CURRENT record and its raw license so a
     * renewed import can replace it.
     */
    private Optional<LicenseRuntimeStatus> applyExpiredValidation(Long tenantId,
                                                                  DeploymentLicenseState state,
                                                                  DeploymentLicense current,
                                                                  LicenseValidationResult result,
                                                                  Instant now) {
        state.transitionTo(LicenseRuntimeStatus.EXPIRED, current.getLicenseId(), now,
                ErrorCode.LICENSE_EXPIRED.name(), null);
        stateRepository.save(state);
        current.markValidated(now, LicenseValidationOutcome.EXPIRED,
                ErrorCode.LICENSE_EXPIRED.name());
        licenseRepository.save(current);
        safeDowngrade(tenantId);
        writeEvent(current.getLicenseId(), tenantId, LicenseEventType.VALIDATION_EXPIRED,
                LicenseValidationOutcome.EXPIRED.name(),
                ErrorCode.LICENSE_EXPIRED.name(),
                Map.of("expiresAt", String.valueOf(current.getExpiresAt()),
                        "reason", result.getMessage().orElse("")), null, now);
        log.info("License expired for tenant {}; subscription downgraded to FREE", tenantId);
        return Optional.of(LicenseRuntimeStatus.EXPIRED);
    }

    private Optional<LicenseRuntimeStatus> applySuccessfulValidation(Long tenantId,
                                                                     DeploymentLicenseState state,
                                                                     DeploymentLicense current,
                                                                     LicensePayload payload,
                                                                     LicenseRuntimeStatus previousStatus,
                                                                     Instant now) {
        // Fully valid: recover to VALID (self-healing against manual edits).
        boolean recovered = previousStatus != LicenseRuntimeStatus.VALID;
        state.transitionTo(LicenseRuntimeStatus.VALID, current.getLicenseId(), now, null, null);
        stateRepository.save(state);
        current.markValidated(now, LicenseValidationOutcome.VALID, null);
        licenseRepository.save(current);
        if (recovered) {
            remapSubscription(tenantId, current);
        }
        writeEvent(current.getLicenseId(), tenantId,
                recovered ? LicenseEventType.VALIDATION_RECOVERED : LicenseEventType.VALIDATION_PASSED,
                LicenseValidationOutcome.VALID.name(), null,
                Map.of("licenseType", current.getLicenseType() != null
                        ? current.getLicenseType().name() : ""), null, now);
        return Optional.of(LicenseRuntimeStatus.VALID);
    }

    /**
     * Re-drive the subscription mapping after recovery so a hand-edited state
     * row heals back to the license-declared subscription (design §9).
     */
    private void remapSubscription(Long tenantId, DeploymentLicense current) {
        try {
            if (current.getLicenseType()
                    == LicenseType.TRIAL) {
                // A TRIAL license may only restore a missing/active trial; a
                // subscription already degraded to FREE stays FREE (same rule
                // as import).
                subscriptionPort.applyTrialLicense(tenantId, current.getExpiresAt());
            } else if (current.getLicenseType()
                    == LicenseType.ACTIVE) {
                subscriptionPort.applyActiveLicense(tenantId, current.getTier(),
                        current.getExpiresAt());
            }
        } catch (DomainException e) {
            // e.g. trial license over a FREE subscription — keep the runtime
            // VALID but leave the subscription untouched.
            log.warn("Subscription remap skipped for tenant {}: {}", tenantId, e.getMessage());
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private LicenseValidationResult validateRaw(DeploymentLicense current,
                                                DeploymentInstallation installation,
                                                Long tenantId, Instant now) {
        try {
            LicenseEnvelope envelope = LicenseEnvelope.parse(current.getRawLicense());
            HostFingerprint fingerprint = fingerprintReader.read();
            LicenseBinding binding = new LicenseBinding(tenantId, installation.getInstallationId(),
                    fingerprint);
            return licenseValidator.validate(envelope, binding, now);
        } catch (Exception e) {
            // Stored raw text unreadable → treat as cryptographically invalid.
            return LicenseValidationResult.failure(
                    ErrorCode.LICENSE_INVALID,
                    "stored license unreadable: " + e.getMessage());
        }
    }

    private LicenseValidationOutcome outcomeFor(ErrorCode errorCode) {
        return switch (errorCode) {
            case LICENSE_EXPIRED -> LicenseValidationOutcome.EXPIRED;
            case LICENSE_BINDING_MISMATCH -> LicenseValidationOutcome.BINDING_MISMATCH;
            default -> LicenseValidationOutcome.INVALID;
        };
    }

    private void safeSuspend(Long tenantId, String reason) {
        try {
            subscriptionPort.suspendForLicense(tenantId, reason);
        } catch (DomainException e) {
            // Port only supports ACTIVE→SUSPENDED; TRIAL/FREE subscriptions
            // stay untouched while the runtime hold still applies.
            log.warn("Subscription suspend skipped for tenant {}: {}", tenantId, e.getMessage());
        }
    }

    private void safeDowngrade(Long tenantId) {
        try {
            subscriptionPort.downgradeForLicense(tenantId);
        } catch (DomainException e) {
            log.warn("Subscription downgrade skipped for tenant {}: {}", tenantId, e.getMessage());
        }
    }

    private void writeEvent(UUID licenseIdIgnored, Long tenantId, LicenseEventType eventType,
                            String result, String errorCode, Map<String, Object> details,
                            Long operatorId, Instant now) {
        try {
            eventRepository.save(DeploymentLicenseEvent.of(licenseIdIgnored, tenantId, eventType,
                    result, errorCode, new LinkedHashMap<>(details), operatorId, now));
        } catch (Exception e) {
            // Audit best-effort: never mask the business outcome.
            log.error("Failed to persist license validation event {} for tenant {}",
                    eventType, tenantId, e);
        }
    }
}
