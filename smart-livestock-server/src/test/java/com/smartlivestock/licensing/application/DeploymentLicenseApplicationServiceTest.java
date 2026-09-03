package com.smartlivestock.licensing.application;

import com.smartlivestock.licensing.application.port.LicenseSubscriptionPort;
import com.smartlivestock.licensing.application.port.LicenseUsagePort;
import com.smartlivestock.licensing.domain.DeploymentInstallation;
import com.smartlivestock.licensing.domain.DeploymentLicense;
import com.smartlivestock.licensing.domain.DeploymentLicenseEvent;
import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.HostFingerprint;
import com.smartlivestock.licensing.domain.LicenseEventType;
import com.smartlivestock.licensing.domain.LicenseRecordStatus;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import com.smartlivestock.licensing.domain.repository.DeploymentInstallationRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseEventRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.licensing.infrastructure.ClasspathLicensePublicKeyRegistry;
import com.smartlivestock.licensing.infrastructure.Ed25519LicenseVerifier;
import com.smartlivestock.licensing.infrastructure.HostFingerprintReader;
import com.smartlivestock.licensing.testsupport.LicenseTestSupport;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.common.MessageResolver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the offline import pipeline and enrollment
 * (NIX-184 T4a). Uses the real Ed25519 verifier with the shared test key so
 * the full cryptographic chain is exercised; repositories and ports are
 * mocked.
 */
@ExtendWith(MockitoExtension.class)
class DeploymentLicenseApplicationServiceTest {

    private static final Long TENANT_ID = 42L;
    private static final String INSTALLATION_ID = "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40";

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
    @Mock
    private LicenseUsagePort usagePort;
    @Mock
    private MessageResolver messageResolver;

    private Ed25519LicenseVerifier verifier;

    @BeforeEach
    void setUp() {
        ClasspathLicensePublicKeyRegistry registry = LicenseTestSupport.testRegistry();
        verifier = new Ed25519LicenseVerifier(registry, LicenseTestSupport.serializer(),
                Duration.ofMinutes(2));
        lenient().when(licenseRepository.save(any(DeploymentLicense.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        lenient().when(stateRepository.save(any(DeploymentLicenseState.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        lenient().when(eventRepository.save(any(DeploymentLicenseEvent.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        lenient().when(fingerprintReader.read())
                .thenReturn(HostFingerprint.of(LicenseTestSupport.FINGERPRINT_HASH));
    }

    private DeploymentLicenseApplicationService createService() {
        return new DeploymentLicenseApplicationService(installationRepository, licenseRepository,
                stateRepository, eventRepository, verifier, fingerprintReader,
                LicenseTestSupport.testRegistry(), subscriptionPort, usagePort, messageResolver);
    }

    private DeploymentInstallation installation() {
        DeploymentInstallation installation = DeploymentInstallation.create(TENANT_ID,
                HostFingerprint.of(LicenseTestSupport.FINGERPRINT_HASH), Instant.now());
        // Align with the fixed installationId carried by the fixture payloads.
        installation.restoreIdentity(java.util.UUID.fromString(INSTALLATION_ID),
                LicenseTestSupport.FINGERPRINT_HASH);
        return installation;
    }

    private void stubInstallation() {
        lenient().when(installationRepository.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(installation()));
    }

    private void stubNoState() {
        lenient().when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());
    }

    /** Payload map matching the fixture installation (binding-compatible). */
    private Map<String, Object> payloadMap() {
        return LicenseTestSupport.validPayloadMap();
    }

    private Map<String, Object> payloadMapWithType(String licenseType, String tier) {
        Map<String, Object> map = payloadMap();
        map.put("licenseType", licenseType);
        map.put("tier", tier);
        return map;
    }

    private String envelopeJson(Map<String, Object> payload) {
        return LicenseTestSupport.buildEnvelopeJson(payload);
    }

    private void stubSubscription(String status, Instant trialEndsAt, boolean trialActive) {
        lenient().when(subscriptionPort.findSubscription(TENANT_ID)).thenReturn(Optional.of(
                new LicenseSubscriptionPort.LicenseSubscriptionSnapshot(status, trialEndsAt,
                        trialActive)));
    }

    // ── enroll ───────────────────────────────────────────────────────

    @Nested
    class Enroll {

        @Test
        void firstEnroll_createsInstallationWithGeneratedId() {
            when(installationRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());
            when(installationRepository.save(any(DeploymentInstallation.class)))
                    .thenAnswer(invocation -> invocation.getArgument(0));

            DeploymentLicenseApplicationService.EnrollmentInfo info =
                    createService().enroll(TENANT_ID);

            assertThat(info.installationId()).isNotBlank();
            assertThat(info.fingerprintHash()).isEqualTo(LicenseTestSupport.FINGERPRINT_HASH);
            assertThat(info.publicKeyId()).isEqualTo(LicenseTestSupport.TEST_KEY_ID);
            assertThat(info.supportedPublicKeyIds()).contains(LicenseTestSupport.TEST_KEY_ID);
            verify(installationRepository).save(any(DeploymentInstallation.class));
        }

        @Test
        void reEnroll_keepsInstallationIdStable() {
            DeploymentInstallation existing = installation();
            when(installationRepository.findByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(existing));

            DeploymentLicenseApplicationService.EnrollmentInfo first =
                    createService().enroll(TENANT_ID);
            DeploymentLicenseApplicationService.EnrollmentInfo second =
                    createService().enroll(TENANT_ID);

            assertThat(first.installationId()).isEqualTo(existing.getInstallationId().toString());
            assertThat(second.installationId()).isEqualTo(first.installationId());
            verify(installationRepository, never()).save(any(DeploymentInstallation.class));
        }
    }

    // ── import: guards ───────────────────────────────────────────────

    @Nested
    class ImportGuards {

        @Test
        void notConfirmed_rejectsWithValidationError() {
            assertThatThrownBy(() -> createService()
                    .importLicense(TENANT_ID, envelopeJson(payloadMap()), false))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                            .isEqualTo(ErrorCode.VALIDATION_ERROR));
        }

        @Test
        void notEnrolled_rejectsWithValidationError() {
            when(installationRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> createService()
                    .importLicense(TENANT_ID, envelopeJson(payloadMap()), true))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                            .isEqualTo(ErrorCode.VALIDATION_ERROR));
        }

        @Test
        void unreadableEnvelope_writesRejectedEventAndThrowsInvalid() {
            stubInstallation();

            assertThatThrownBy(() -> createService().importLicense(TENANT_ID, "not json", true))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                            .isEqualTo(ErrorCode.LICENSE_INVALID));

            ArgumentCaptor<DeploymentLicenseEvent> eventCaptor =
                    ArgumentCaptor.forClass(DeploymentLicenseEvent.class);
            verify(eventRepository).save(eventCaptor.capture());
            assertThat(eventCaptor.getValue().getEventType())
                    .isEqualTo(LicenseEventType.IMPORT_REJECTED);
            assertThat(eventCaptor.getValue().getErrorCode())
                    .isEqualTo(ErrorCode.LICENSE_INVALID.name());
        }
    }

    // ── import: successful acceptance ────────────────────────────────

    @Nested
    class ImportAccepted {

        @Test
        void trialImportWithoutSubscription_appliesTrialAndStoresCurrentLicense() {
            stubInstallation();
            stubNoState();
            when(subscriptionPort.findSubscription(TENANT_ID)).thenReturn(Optional.empty());
            lenient().when(usagePort.countCurrentUsage(anyLong(), anyString())).thenReturn(0);

            Instant expiresAt = (Instant) payloadMap().get("expiresAt");
            DeploymentLicenseApplicationService.ImportResult result = createService()
                    .importLicense(TENANT_ID, envelopeJson(payloadMap()), true);

            assertThat(result.runtimeStatus()).isEqualTo(LicenseRuntimeStatus.VALID.name());
            assertThat(result.licenseType()).isEqualTo("TRIAL");
            assertThat(result.expiresAt()).isEqualTo(expiresAt);
            verify(subscriptionPort).applyTrialLicense(TENANT_ID, expiresAt);

            ArgumentCaptor<DeploymentLicense> licenseCaptor =
                    ArgumentCaptor.forClass(DeploymentLicense.class);
            verify(licenseRepository, times(1)).save(licenseCaptor.capture());
            assertThat(licenseCaptor.getValue().getStatus()).isEqualTo(LicenseRecordStatus.CURRENT);
            assertThat(licenseCaptor.getValue().getTenantId()).isEqualTo(TENANT_ID);

            ArgumentCaptor<DeploymentLicenseState> stateCaptor =
                    ArgumentCaptor.forClass(DeploymentLicenseState.class);
            verify(stateRepository).save(stateCaptor.capture());
            assertThat(stateCaptor.getValue().getRuntimeStatus())
                    .isEqualTo(LicenseRuntimeStatus.VALID);

            ArgumentCaptor<DeploymentLicenseEvent> eventCaptor =
                    ArgumentCaptor.forClass(DeploymentLicenseEvent.class);
            verify(eventRepository).save(eventCaptor.capture());
            assertThat(eventCaptor.getValue().getEventType())
                    .isEqualTo(LicenseEventType.IMPORT_ACCEPTED);
        }

        @Test
        void trialImportOverActiveTrial_extendsTrial() {
            stubInstallation();
            stubNoState();
            Instant trialEndsAt = Instant.now().plus(Duration.ofDays(10));
            stubSubscription("TRIAL", trialEndsAt, true);
            lenient().when(usagePort.countCurrentUsage(anyLong(), anyString())).thenReturn(0);

            Instant payloadExpiry = (Instant) payloadMap().get("expiresAt");
            createService().importLicense(TENANT_ID, envelopeJson(payloadMap()), true);

            verify(subscriptionPort).applyTrialLicense(TENANT_ID, payloadExpiry);
        }

        @Test
        void activeImportFromFreeSubscription_activatesWithTier() {
            stubInstallation();
            stubNoState();
            stubSubscription("FREE", null, false);
            lenient().when(usagePort.countCurrentUsage(anyLong(), anyString())).thenReturn(0);

            Map<String, Object> payload = payloadMapWithType("ACTIVE", "PREMIUM");
            Instant expiresAt = (Instant) payload.get("expiresAt");

            DeploymentLicenseApplicationService.ImportResult result = createService()
                    .importLicense(TENANT_ID, envelopeJson(payload), true);

            assertThat(result.licenseType()).isEqualTo("ACTIVE");
            verify(subscriptionPort).applyActiveLicense(TENANT_ID, "PREMIUM", expiresAt);
        }

        @Test
        void importReplacesPreviousLicense_oldRecordMarkedReplaced() {
            stubInstallation();
            stubNoState();
            stubSubscription("TRIAL", Instant.now().plus(Duration.ofDays(10)), true);
            lenient().when(usagePort.countCurrentUsage(anyLong(), anyString())).thenReturn(0);

            // Previous CURRENT license from an earlier import.
            DeploymentLicense previous = DeploymentLicense.accept(
                    com.smartlivestock.licensing.domain.LicensePayload.fromMap(
                            LicenseTestSupport.serializer().parse(
                                    LicenseTestSupport.buildEnvelope(payloadMap())
                                            .decodePayload())),
                    TENANT_ID, envelopeJson(payloadMap()), null, Instant.now().minusSeconds(60));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(previous));

            Map<String, Object> nextPayload = payloadMapWithType("ACTIVE", "STANDARD");
            nextPayload.put("licenseId", "4f2b8a5e-0c1d-4e2f-9a8b-7c6d5e4f3a2c");
            createService().importLicense(TENANT_ID, envelopeJson(nextPayload), true);

            assertThat(previous.getStatus()).isEqualTo(LicenseRecordStatus.REPLACED);
            ArgumentCaptor<DeploymentLicense> licenseCaptor =
                    ArgumentCaptor.forClass(DeploymentLicense.class);
            verify(licenseRepository, times(2)).save(licenseCaptor.capture());
            assertThat(licenseCaptor.getAllValues().get(0).getStatus())
                    .isEqualTo(LicenseRecordStatus.REPLACED);
            assertThat(licenseCaptor.getAllValues().get(1).getStatus())
                    .isEqualTo(LicenseRecordStatus.CURRENT);
            assertThat(licenseCaptor.getAllValues().get(1).getReplacesLicenseId())
                    .isEqualTo(previous.getLicenseId());
        }
    }

    // ── import: rejections ───────────────────────────────────────────

    @Nested
    class ImportRejected {

        @Test
        void bindingMismatch_persistsRejectedRecordAndThrows() {
            stubInstallation();
            stubNoState();

            Map<String, Object> payload = payloadMap();
            payload.put("fingerprintHash",
                    "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");

            assertThatThrownBy(() -> createService()
                    .importLicense(TENANT_ID, envelopeJson(payload), true))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                            .isEqualTo(ErrorCode.LICENSE_BINDING_MISMATCH));

            ArgumentCaptor<DeploymentLicense> licenseCaptor =
                    ArgumentCaptor.forClass(DeploymentLicense.class);
            verify(licenseRepository).save(licenseCaptor.capture());
            assertThat(licenseCaptor.getValue().getStatus())
                    .isEqualTo(LicenseRecordStatus.REJECTED);
            verify(subscriptionPort, never()).applyTrialLicense(anyLong(), any());
            verify(subscriptionPort, never()).applyActiveLicense(anyLong(), anyString(), any());

            ArgumentCaptor<DeploymentLicenseEvent> eventCaptor =
                    ArgumentCaptor.forClass(DeploymentLicenseEvent.class);
            verify(eventRepository).save(eventCaptor.capture());
            assertThat(eventCaptor.getValue().getEventType())
                    .isEqualTo(LicenseEventType.IMPORT_REJECTED);
            assertThat(eventCaptor.getValue().getErrorCode())
                    .isEqualTo(ErrorCode.LICENSE_BINDING_MISMATCH.name());
        }

        @Test
        void quotaExceeded_rejectsImportWithoutTouchingSubscription() {
            stubInstallation();
            stubNoState();
            stubSubscription("TRIAL", Instant.now().plus(Duration.ofDays(10)), true);
            when(usagePort.countCurrentUsage(TENANT_ID, "livestock_management")).thenReturn(2000);

            assertThatThrownBy(() -> createService()
                    .importLicense(TENANT_ID, envelopeJson(payloadMap()), true))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                            .isEqualTo(ErrorCode.LICENSE_QUOTA_EXCEEDED));

            verify(subscriptionPort, never()).applyTrialLicense(anyLong(), any());
            verify(licenseRepository, never()).save(
                    org.mockito.ArgumentMatchers.argThat(
                            (DeploymentLicense l) -> l != null && l.isCurrent()));
            ArgumentCaptor<DeploymentLicenseEvent> eventCaptor =
                    ArgumentCaptor.forClass(DeploymentLicenseEvent.class);
            verify(eventRepository).save(eventCaptor.capture());
            assertThat(eventCaptor.getValue().getErrorCode())
                    .isEqualTo(ErrorCode.LICENSE_QUOTA_EXCEEDED.name());
        }

        @Test
        void quotaKeyAbsentFromPayload_skipsThatPrecheck() {
            stubInstallation();
            stubNoState();
            stubSubscription("TRIAL", Instant.now().plus(Duration.ofDays(10)), true);
            when(usagePort.countCurrentUsage(TENANT_ID, "livestock_management")).thenReturn(0);

            Map<String, Object> payload = payloadMap();
            Map<String, Object> quotas = new LinkedHashMap<>();
            quotas.put("livestock_management", 1000);
            payload.put("quotas", quotas);

            createService().importLicense(TENANT_ID, envelopeJson(payload), true);

            // Only the key carried by the payload is pre-checked.
            verify(usagePort, times(1)).countCurrentUsage(anyLong(), anyString());
            verify(usagePort).countCurrentUsage(TENANT_ID, "livestock_management");
        }

        @Test
        void trialImportAfterTrialDegradedToFree_rejects() {
            stubInstallation();
            stubNoState();
            stubSubscription("FREE", null, false);
            lenient().when(usagePort.countCurrentUsage(anyLong(), anyString())).thenReturn(0);

            assertThatThrownBy(() -> createService()
                    .importLicense(TENANT_ID, envelopeJson(payloadMap()), true))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                            .isEqualTo(ErrorCode.STATE_CONFLICT));

            verify(subscriptionPort, never()).applyTrialLicense(anyLong(), any());
        }

        @Test
        void trialImportOverExpiredTrial_rejects() {
            stubInstallation();
            stubNoState();
            // TRIAL status but the trial window already passed.
            stubSubscription("TRIAL", Instant.now().minus(Duration.ofDays(1)), false);
            lenient().when(usagePort.countCurrentUsage(anyLong(), anyString())).thenReturn(0);

            assertThatThrownBy(() -> createService()
                    .importLicense(TENANT_ID, envelopeJson(payloadMap()), true))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                            .isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void expiredLicenseImport_rejectedAsExpired() {
            stubInstallation();
            stubNoState();

            Map<String, Object> payload = payloadMap();
            payload.put("issuedAt", Instant.now().minus(Duration.ofDays(400)));
            payload.put("expiresAt", Instant.now().minus(Duration.ofDays(35)));

            assertThatThrownBy(() -> createService()
                    .importLicense(TENANT_ID, envelopeJson(payload), true))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                            .isEqualTo(ErrorCode.LICENSE_EXPIRED));

            verify(subscriptionPort, never()).applyTrialLicense(anyLong(), any());
            verify(subscriptionPort, never()).applyActiveLicense(anyLong(), anyString(), any());
        }
    }

    // ── currentStatus ────────────────────────────────────────────────

    @Nested
    class CurrentStatus {

        @Test
        void reportsInstallationLicenseStateAndSubscription() {
            stubInstallation();
            stubSubscription("TRIAL", Instant.now().plus(Duration.ofDays(10)), true);
            // A CURRENT license previously stored by an accepted import.
            byte[] canonicalBytes = LicenseTestSupport.buildEnvelope(payloadMap()).decodePayload();
            DeploymentLicense stored = DeploymentLicense.accept(
                    com.smartlivestock.licensing.domain.LicensePayload.fromMap(
                            LicenseTestSupport.serializer().parse(canonicalBytes)),
                    TENANT_ID, envelopeJson(payloadMap()), null, Instant.now().minusSeconds(60));
            when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(stored));
            DeploymentLicenseState state = DeploymentLicenseState.initial(TENANT_ID, Instant.now());
            state.advanceTime(Instant.now());
            state.transitionTo(LicenseRuntimeStatus.VALID, stored.getLicenseId(),
                    Instant.now(), null, null);
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(state));

            DeploymentLicenseApplicationService.DeploymentLicenseStatus status =
                    createService().currentStatus(TENANT_ID);

            assertThat(status.installationId()).isEqualTo(INSTALLATION_ID);
            assertThat(status.fingerprintHash()).isEqualTo(LicenseTestSupport.FINGERPRINT_HASH);
            assertThat(status.runtimeStatus()).isEqualTo(LicenseRuntimeStatus.VALID.name());
            assertThat(status.licenseId()).isEqualTo(stored.getLicenseId().toString());
            assertThat(status.licenseType()).isEqualTo("TRIAL");
            assertThat(status.subscriptionStatus()).isEqualTo("TRIAL");
            assertThat(status.maxObservedAt()).isNotNull();
            assertThat(status.protectionReason()).isNull();
        }

        @Test
        void beforeEnroll_reportsPendingActivation() {
            when(installationRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());
            lenient().when(licenseRepository.findCurrentByTenantId(TENANT_ID))
                    .thenReturn(Optional.empty());
            lenient().when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());
            when(subscriptionPort.findSubscription(TENANT_ID)).thenReturn(Optional.empty());

            DeploymentLicenseApplicationService.DeploymentLicenseStatus status =
                    createService().currentStatus(TENANT_ID);

            assertThat(status.installationId()).isNull();
            assertThat(status.runtimeStatus())
                    .isEqualTo(LicenseRuntimeStatus.PENDING_ACTIVATION.name());
            assertThat(status.licenseId()).isNull();
            assertThat(status.subscriptionStatus()).isNull();
        }
    }
}
