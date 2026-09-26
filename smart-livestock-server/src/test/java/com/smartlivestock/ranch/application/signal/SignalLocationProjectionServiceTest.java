package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.LivestockLocationSnapshotJpaRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.LivestockLocationSnapshotJpaEntity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SignalLocationProjectionServiceTest {

    @Mock
    private LivestockLocationSnapshotJpaRepository snapshotRepository;
    @Mock
    private SignalRevisionService revisionService;
    @Mock
    private LivestockRepository livestockRepository;

    private SignalLocationProjectionService service;

    @BeforeEach
    void setUp() {
        service = new SignalLocationProjectionService(
                snapshotRepository, revisionService, livestockRepository
        );
    }

    @Test
    void acceptsNewerFixAndProjectsRevision() {
        when(revisionService.bumpPosition(1L)).thenReturn(96L);
        when(livestockRepository.findById(14L)).thenReturn(Optional.of(new Livestock()));

        boolean accepted = service.projectCurrentFix(
                14L, 1L, 7L,
                new BigDecimal("28.2465"), new BigDecimal("112.8513"),
                new BigDecimal("8.2"), Instant.parse("2026-09-27T10:00:00Z"),
                "AGENTIC_PLATFORM"
        );

        assertThat(accepted).isTrue();
        ArgumentCaptor<LivestockLocationSnapshotJpaEntity> captor =
                ArgumentCaptor.forClass(LivestockLocationSnapshotJpaEntity.class);
        verify(snapshotRepository).save(captor.capture());
        assertThat(captor.getValue().getPositionRevision()).isEqualTo(96L);
        assertThat(captor.getValue().getSource()).isEqualTo("AGENTIC_PLATFORM");
    }

    @Test
    void ignoresOlderFix() {
        LivestockLocationSnapshotJpaEntity existing = new LivestockLocationSnapshotJpaEntity();
        existing.setRecordedAt(Instant.parse("2026-09-27T10:00:00Z"));
        when(snapshotRepository.findByLivestockId(14L)).thenReturn(Optional.of(existing));

        boolean accepted = service.projectCurrentFix(
                14L, 1L, 7L,
                new BigDecimal("28.2465"), new BigDecimal("112.8513"),
                null, Instant.parse("2026-09-27T09:00:00Z"), "AGENTIC_PLATFORM"
        );

        assertThat(accepted).isFalse();
        verify(snapshotRepository, never()).save(any());
        verify(revisionService, never()).bumpPosition(1L);
    }

    @Test
    void rejectsInvalidSourceOrCoordinate() {
        assertThat(service.projectCurrentFix(
                14L, 1L, 7L,
                new BigDecimal("91"), new BigDecimal("112"),
                null, Instant.now(), "AGENTIC_PLATFORM"
        )).isFalse();
        assertThat(service.projectCurrentFix(
                14L, 1L, 7L,
                new BigDecimal("28"), new BigDecimal("112"),
                null, Instant.now(), "DEVICE"
        )).isFalse();
    }
}
