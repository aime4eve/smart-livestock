package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.TelemetryDedupApplicationService.Observation;
import com.smartlivestock.iot.application.TelemetryDedupApplicationService.Result;
import com.smartlivestock.iot.infrastructure.persistence.SpringDataTelemetryIngestionDedupRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.TelemetryIngestionDedupJpaEntity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Arbitration branches of the NIX-370 dedup registry (parking NIX-120/125/252
 * pattern): same-source idempotency, ±2s neighbor + fingerprint merging,
 * ambiguity and the same-canonical-key guard.
 */
class TelemetryDedupApplicationServiceTest {

    private SpringDataTelemetryIngestionDedupRepository repository;
    private TelemetryDedupApplicationService service;

    @BeforeEach
    void setUp() {
        repository = mock(SpringDataTelemetryIngestionDedupRepository.class);
        service = new TelemetryDedupApplicationService(repository);
    }

    private Observation observation(long ts, String fingerprint) {
        return new Observation(122L, "THINGSBOARD", "tb-rest", "tb-uuid",
                Instant.ofEpochMilli(ts), ts, fingerprint);
    }

    private TelemetryIngestionDedupJpaEntity canonical(long ts, String fingerprint) {
        TelemetryIngestionDedupJpaEntity entity = new TelemetryIngestionDedupJpaEntity();
        entity.setProvider("THINGSBOARD");
        entity.setChannel("tb-rest");
        entity.setDeviceId(122L);
        entity.setExternalDeviceId("tb-uuid");
        entity.setProviderEventTs(ts);
        entity.setCanonical(true);
        entity.setCanonicalKey("key-" + ts);
        entity.setCoreFieldsFingerprint(fingerprint);
        return entity;
    }

    @Test
    void firstObservationBecomesCanonical() {
        when(repository.findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
                anyString(), anyString(), anyLong(), anyString())).thenReturn(Optional.empty());
        when(repository.findByDeviceIdAndCanonical(122L, true)).thenReturn(List.of());
        when(repository.findByCanonicalKeyAndCanonical(anyString(), org.mockito.ArgumentMatchers.eq(true)))
                .thenReturn(Optional.empty());

        Result result = service.register(observation(1000L, "fp-a"));

        assertThat(result).isEqualTo(Result.CANONICAL);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<TelemetryIngestionDedupJpaEntity> captor =
                ArgumentCaptor.forClass(TelemetryIngestionDedupJpaEntity.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().isCanonical()).isTrue();
        assertThat(captor.getValue().getCoreFieldsFingerprint()).isEqualTo("fp-a");
    }

    @Test
    void sameSourceObservationIsSourceDuplicate() {
        when(repository.findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
                anyString(), anyString(), anyLong(), anyString()))
                .thenReturn(Optional.of(canonical(1000L, "fp-a")));

        Result result = service.register(observation(1000L, "fp-a"));

        assertThat(result).isEqualTo(Result.SOURCE_DUPLICATE);
        verify(repository, never()).save(any());
    }

    @Test
    void nearNeighborWithSameFingerprintMergesAsDuplicate() {
        // The NIX-370 shape: upstream re-write ~134ms later, same payload.
        when(repository.findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
                anyString(), anyString(), anyLong(), anyString())).thenReturn(Optional.empty());
        when(repository.findByDeviceIdAndCanonical(122L, true))
                .thenReturn(List.of(canonical(1000L, "fp-a")));

        Result result = service.register(observation(1134L, "fp-a"));

        assertThat(result).isEqualTo(Result.MATCHED_DUPLICATE);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<TelemetryIngestionDedupJpaEntity> captor =
                ArgumentCaptor.forClass(TelemetryIngestionDedupJpaEntity.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().isCanonical()).isFalse();
        assertThat(captor.getValue().getMatchedCanonicalKey()).isEqualTo("key-1000");
    }

    @Test
    void neighborBeyondMatchWindowIsIndependentCanonical() {
        when(repository.findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
                anyString(), anyString(), anyLong(), anyString())).thenReturn(Optional.empty());
        when(repository.findByDeviceIdAndCanonical(122L, true))
                .thenReturn(List.of(canonical(1000L, "fp-a")));
        when(repository.findByCanonicalKeyAndCanonical(anyString(), org.mockito.ArgumentMatchers.eq(true)))
                .thenReturn(Optional.empty());

        // 2.5s later — outside the ±2s window: a real independent frame.
        Result result = service.register(observation(3500L, "fp-a"));

        assertThat(result).isEqualTo(Result.CANONICAL);
    }

    @Test
    void neighborWithDifferentFingerprintIsIndependentCanonical() {
        when(repository.findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
                anyString(), anyString(), anyLong(), anyString())).thenReturn(Optional.empty());
        when(repository.findByDeviceIdAndCanonical(122L, true))
                .thenReturn(List.of(canonical(1000L, "fp-a")));
        when(repository.findByCanonicalKeyAndCanonical(anyString(), org.mockito.ArgumentMatchers.eq(true)))
                .thenReturn(Optional.empty());

        Result result = service.register(observation(1134L, "fp-b"));

        assertThat(result).isEqualTo(Result.CANONICAL);
    }

    @Test
    void twoFingerprintMatchingNeighborsAreAmbiguous() {
        when(repository.findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
                anyString(), anyString(), anyLong(), anyString())).thenReturn(Optional.empty());
        when(repository.findByDeviceIdAndCanonical(122L, true))
                .thenReturn(List.of(canonical(1000L, "fp-a"), canonical(1600L, "fp-a")));

        Result result = service.register(observation(1200L, "fp-a"));

        assertThat(result).isEqualTo(Result.AMBIGUOUS);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<TelemetryIngestionDedupJpaEntity> captor =
                ArgumentCaptor.forClass(TelemetryIngestionDedupJpaEntity.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().isCanonical()).isFalse();
        assertThat(captor.getValue().getMatchedCanonicalKey()).isNull();
    }

    @Test
    void sameCanonicalKeyFingerprintDriftFallsBackToDuplicate() {
        // parking NIX-252: neighbor filtered by fingerprint drift, but the
        // canonical key (provider|externalDeviceId|ts) already stands — the
        // observation IS that frame and must merge, not violate the unique index.
        when(repository.findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
                anyString(), anyString(), anyLong(), anyString())).thenReturn(Optional.empty());
        when(repository.findByDeviceIdAndCanonical(122L, true)).thenReturn(List.of());
        when(repository.findByCanonicalKeyAndCanonical(anyString(), org.mockito.ArgumentMatchers.eq(true)))
                .thenReturn(Optional.of(canonical(1000L, "fp-drift")));

        Result result = service.register(observation(1000L, "fp-b"));

        assertThat(result).isEqualTo(Result.MATCHED_DUPLICATE);
    }

    @Test
    void arbitrationLocksAcquiredPerObservation() {
        when(repository.findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
                anyString(), anyString(), anyLong(), anyString())).thenReturn(Optional.empty());
        when(repository.findByDeviceIdAndCanonical(122L, true)).thenReturn(List.of());
        when(repository.findByCanonicalKeyAndCanonical(anyString(), org.mockito.ArgumentMatchers.eq(true)))
                .thenReturn(Optional.empty());

        service.register(observation(1000L, "fp-a"));

        verify(repository, times(2)).acquireAdvisoryLock(anyString());
    }

    @Test
    void fingerprintIsStableAndOrderIndependent() {
        String a = TelemetryDedupApplicationService.coreFieldsFingerprint(
                java.util.Map.of("battery", 99, "stepNumber", 123));
        String b = TelemetryDedupApplicationService.coreFieldsFingerprint(
                java.util.Map.of("stepNumber", 123, "battery", 99));

        assertThat(a).isEqualTo(b).hasSize(64);
    }

    @Test
    void fingerprintExcludesWirelessParams() {
        // The observed duplicates differ only in rssi/snr — those must not
        // participate in the fingerprint or merging would never trigger.
        String without = TelemetryDedupApplicationService.coreFieldsFingerprint(
                java.util.Map.of("battery", 99));
        String withWireless = TelemetryDedupApplicationService.coreFieldsFingerprint(
                java.util.Map.of("battery", 99, "rssi", -94, "snr", 8.0));

        assertThat(without).isEqualTo(withWireless);
    }
}
