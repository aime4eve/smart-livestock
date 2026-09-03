package com.smartlivestock.licensing.application;

import com.smartlivestock.licensing.application.port.LicenseSubscriptionPort;
import com.smartlivestock.licensing.domain.DeploymentInstallation;
import com.smartlivestock.licensing.domain.DeploymentLicense;
import com.smartlivestock.licensing.domain.DeploymentLicenseEvent;
import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.HostFingerprint;
import com.smartlivestock.licensing.domain.LicenseEventType;
import com.smartlivestock.licensing.domain.LicensePayload;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import com.smartlivestock.licensing.domain.LicenseType;
import com.smartlivestock.licensing.domain.repository.DeploymentInstallationRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseEventRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.licensing.infrastructure.ClasspathLicensePublicKeyRegistry;
import com.smartlivestock.licensing.infrastructure.Ed25519LicenseVerifier;
import com.smartlivestock.licensing.infrastructure.HostFingerprintReader;
import com.smartlivestock.licensing.infrastructure.config.LicenseProperties;
import com.smartlivestock.licensing.testsupport.LicenseTestSupport;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the periodic validation state machine
 * (NIX-184 T4b): rollback suspension, expiry downgrade, self-healing
 * recovery from the stored raw license, and event writing.
 */
@ExtendWith(MockitoExtension.class)
class LicenseTimeGuardServiceTest {

    private static final Long TENANT_ID = 42L;

    @Mock
    private DeploymentInstallationRepository installationRepository;
    @Mock
    private DeploymentLicenseRepository licenseRepository;
    @Mock
    private DeploymentLicenseStateRepository stateRepository;
    @Mock
    private DeploymentLicenseEventRepository eventRepository;
    @Mock
    private HostFingerprintReader fingerprintReader;
    @Mock
    private LicenseSubscriptionPort subscriptionPort;

    private LicenseProperties properties;

    @BeforeEach
    void setUp() {
        properties = new LicenseProperties();
        properties.setTimeTolerance(Duration.ofMinutes(2));
        lenient().when(stateRepository.save(any(DeploymentLicenseState.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        lenient().when(licenseRepository.save(any(DeploymentLicense.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        lenient().when(eventRepository.save(any(DeploymentLicenseEvent.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        lenient().when(fingerprintReader.read())
                .thenReturn(HostFingerprint.of(LicenseTestSupport.FINGERPRINT_HASH));
        lenient().when(installationRepository.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(installation()));
    }

    private LicenseTimeGuardService createService() {
        Ed25519LicenseVerifier verifier = new Ed25519LicenseVerifier(
                LicenseTestSupport.testRegistry(), LicenseTestSupport.serializer(),
                properties.getTimeTolerance());
        return new LicenseTimeGuardService(installationRepository, licenseRepository,
                stateRepository, eventRepository, verifier, fingerprintReader,
                subscriptionPort, properties);
    }

    private DeploymentInstallation installation() {
        DeploymentInstallation installation = DeploymentInstallation.create(TENANT_ID,
                HostFingerprint.of(LicenseTestSupport.FINGERPRINT_HASH), Instant.now());
        // Align with the fixed installationId carried by the fixture payloads.
        installation.restoreIdentity(java.util.UUID.fromString(
                "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40"), LicenseTestSupport.FINGERPRINT_HASH);
        return installation;
    }

    /** Raw envelope + stored CURRENT record for a valid (unexpired) license. */
    private DeploymentLicense currentLicense(String licenseType, String tier,
                                             Instant issuedAt, Instant expiresAt) {
        Map<String, Object> payloadMap = LicenseTestSupport.validPayloadMap();
        payloadMap.put("licenseType", licenseType);
        payloadMap.put("tier", tier);
        payloadMap.put("issuedAt", issuedAt);
        payloadMap.put("expiresAt", expiresAt);
        String raw = LicenseTestSupport.buildEnvelopeJson(payloadMap);
        LicensePayload payload = LicensePayload.fromMap(
                LicenseTestSupport.serializer().parse(
                        LicenseTestSupport.buildEnvelope(payloadMap).decodePayload()));
        return DeploymentLicense.accept(payload, TENANT_ID, raw, null,
                Instant.now().minusSeconds(60));
    }

    private DeploymentLicense validCurrentLicense() {
        return currentLicense("ACTIVE", "PREMIUM",
                Instant.now().minus(Duration.ofHours(1)),
                Instant.now().plus(Duration.ofDays(365)));
    }

    private DeploymentLicenseState storedState(LicenseRuntimeStatus status, Instant maxObservedAt) {
        DeploymentLicenseState state = DeploymentLicenseState.initial(TENANT_ID, Instant.now());
        state.advanceTime(maxObservedAt);
        state.transitionTo(status, null, Instant.now(), null, null);
        return state;
    }

    // ── Guard rails ──────────────────────────────────────────────────

    @Nested
    class GuardRails {

        @Test
        void noInstallation_returnsEmptyAndWritesNothing() {
            when(installationRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            assertThat(createService().validateTenant(TENANT_ID)).isEmpty();

            verify(stateRepository, never()).save(any());
            verify(eventRepository, never()).save(any());
        }
    }

    // ── VALID path ───────────────────────────────────────────────────

    @Nested
    class ValidationPassed {

        @Test
        void firstValidationWithValidLicense_marksValidAndAdvancesAnchor() {
            Instant before = Instant.now();
            when(stateRepository.findByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(storedState(LicenseRuntimeStatus.VALID, null)));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(validCurrentLicense()));

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.VALID);
            ArgumentCaptor<DeploymentLicenseState> stateCaptor =
                    ArgumentCaptor.forClass(DeploymentLicenseState.class);
            verify(stateRepository).save(stateCaptor.capture());
            assertThat(stateCaptor.getValue().getMaxObservedAt()).isAfter(before);
            verify(eventRepository).save(org.mockito.ArgumentMatchers.argThat(
                    (DeploymentLicenseEvent e) -> e.getEventType() == LicenseEventType.VALIDATION_PASSED));
        }

        @Test
        void recoveryFromSuspension_revalidatesRawLicenseAndRemapsSubscription() {
            // Time anchor in the past: clock is back to normal after a rollback.
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.SUSPENDED,
                            Instant.now().minus(Duration.ofHours(1)))));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(validCurrentLicense()));

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.VALID);
            // ACTIVE license remaps the subscription on recovery.
            verify(subscriptionPort).applyActiveLicense(eq(TENANT_ID), eq("PREMIUM"), any());
            verify(eventRepository).save(org.mockito.ArgumentMatchers.argThat(
                    (DeploymentLicenseEvent e) -> e.getEventType() == LicenseEventType.VALIDATION_RECOVERED));
        }

        @Test
        void trialLicenseRecoveryOverFreeSubscription_keepsRuntimeValidSkipsRemap() {
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.EXPIRED,
                            Instant.now().minus(Duration.ofHours(1)))));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(currentLicense("TRIAL", "BASIC",
                            Instant.now().minus(Duration.ofHours(2)),
                            Instant.now().plus(Duration.ofDays(30)))));
            // FREE subscription cannot return to TRIAL — same rule as import.
            org.mockito.Mockito.doThrow(new DomainException(ErrorCode.STATE_CONFLICT,
                    "cannot extendTrial")).when(subscriptionPort)
                    .applyTrialLicense(anyLong(), any());

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.VALID);
            verify(subscriptionPort, never()).applyActiveLicense(anyLong(), anyString(), any());
        }
    }

    // ── EXPIRED path ─────────────────────────────────────────────────

    @Nested
    class ValidationExpired {

        @Test
        void expiredLicense_marksExpiredAndDowngradesSubscription() {
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.VALID, Instant.now())));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(currentLicense("ACTIVE", "PREMIUM",
                            Instant.now().minus(Duration.ofDays(400)),
                            Instant.now().minus(Duration.ofDays(35)))));

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.EXPIRED);
            verify(subscriptionPort).downgradeForLicense(TENANT_ID);
            verify(eventRepository).save(org.mockito.ArgumentMatchers.argThat(
                    (DeploymentLicenseEvent e) -> e.getEventType() == LicenseEventType.VALIDATION_EXPIRED));
        }

        @Test
        void downgradeConflict_stillMarksRuntimeExpired() {
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.VALID, Instant.now())));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(currentLicense("ACTIVE", "PREMIUM",
                            Instant.now().minus(Duration.ofDays(400)),
                            Instant.now().minus(Duration.ofDays(35)))));
            org.mockito.Mockito.doThrow(new DomainException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                    "missing")).when(subscriptionPort).downgradeForLicense(TENANT_ID);

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.EXPIRED);
        }
    }

    // ── SUSPENDED path (time rollback) ───────────────────────────────

    @Nested
    class TimeRollback {

        @Test
        void rollbackBeyondTolerance_suspendsAndKeepsAnchorMonotonic() {
            Instant maxObservedAt = Instant.now().plus(Duration.ofHours(1));
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.VALID, maxObservedAt)));

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.SUSPENDED);
            verify(subscriptionPort).suspendForLicense(eq(TENANT_ID), anyString());
            ArgumentCaptor<DeploymentLicenseState> stateCaptor =
                    ArgumentCaptor.forClass(DeploymentLicenseState.class);
            verify(stateRepository).save(stateCaptor.capture());
            assertThat(stateCaptor.getValue().getMaxObservedAt()).isEqualTo(maxObservedAt);
            assertThat(stateCaptor.getValue().getProtectionReason())
                    .isEqualTo(DeploymentLicenseState.PROTECTION_TIME_ROLLBACK);
            verify(eventRepository).save(org.mockito.ArgumentMatchers.argThat(
                    (DeploymentLicenseEvent e) -> e.getEventType() == LicenseEventType.VALIDATION_SUSPENDED));
        }

        @Test
        void rollbackWithinTolerance_staysValid() {
            // 1 minute back in time, tolerance is 2 minutes → no suspension.
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.VALID,
                            Instant.now().plus(Duration.ofMinutes(1)))));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(validCurrentLicense()));

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.VALID);
            verify(subscriptionPort, never()).suspendForLicense(anyLong(), anyString());
        }

        @Test
        void suspendConflict_stillMarksRuntimeSuspended() {
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.VALID,
                            Instant.now().plus(Duration.ofHours(1)))));
            org.mockito.Mockito.doThrow(new DomainException(ErrorCode.STATE_CONFLICT,
                    "cannot suspend from TRIAL")).when(subscriptionPort)
                    .suspendForLicense(anyLong(), anyString());

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.SUSPENDED);
        }
    }

    // ── PENDING_ACTIVATION / tamper paths ────────────────────────────

    @Nested
    class SelfHealing {

        @Test
        void currentLicenseRecordDeleted_fallsBackToPendingActivation() {
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.VALID, Instant.now())));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.PENDING_ACTIVATION);
            verify(eventRepository).save(org.mockito.ArgumentMatchers.argThat(
                    (DeploymentLicenseEvent e) -> e.getEventType() == LicenseEventType.VALIDATION_FAILED));
        }

        @Test
        void tamperedRawLicense_suspendsWithInvalidProtection() throws Exception {
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.VALID, Instant.now())));
            DeploymentLicense tampered = validCurrentLicense();
            // Flip one bit inside the payload bytes: digest + signature break.
            com.smartlivestock.licensing.domain.LicenseEnvelope original =
                    com.smartlivestock.licensing.domain.LicenseEnvelope.parse(
                            tampered.getRawLicense());
            byte[] payloadBytes = original.decodePayload();
            payloadBytes[10] ^= 0x01;
            String tamperedPayloadB64 = java.util.Base64.getUrlEncoder()
                    .encodeToString(payloadBytes);
            tampered.setRawLicense(LicenseTestSupport.envelopeJson(original.getKeyId(),
                    tamperedPayloadB64, original.getPayloadSha256(), original.getSignature()));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(tampered));

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.SUSPENDED);
            ArgumentCaptor<DeploymentLicenseState> stateCaptor =
                    ArgumentCaptor.forClass(DeploymentLicenseState.class);
            verify(stateRepository).save(stateCaptor.capture());
            assertThat(stateCaptor.getValue().getProtectionReason())
                    .isEqualTo(DeploymentLicenseState.PROTECTION_LICENSE_INVALID);
            verify(subscriptionPort).suspendForLicense(eq(TENANT_ID), anyString());
        }

        @Test
        void replacedChainWithoutCurrent_fallsBackToPendingActivation() {
            // Data is never deleted; without a CURRENT record the runtime
            // degrades to PENDING_ACTIVATION even though REPLACED rows exist.
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(
                    storedState(LicenseRuntimeStatus.EXPIRED, Instant.now())));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            Optional<LicenseRuntimeStatus> result = createService().validateTenant(TENANT_ID);

            assertThat(result).contains(LicenseRuntimeStatus.PENDING_ACTIVATION);
            verify(subscriptionPort, never()).downgradeForLicense(anyLong());
        }
    }
}
