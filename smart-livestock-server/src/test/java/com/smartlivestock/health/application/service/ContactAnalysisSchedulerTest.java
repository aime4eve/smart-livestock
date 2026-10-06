package com.smartlivestock.health.application.service;

import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Pure-JVM unit tests for the scheduler wiring only (farm iteration, failure
 * isolation, on/off switch, window cutoff). The analysis kernel itself is
 * covered by ContactAnalysisServiceTest / ContactAnalysisServiceIntegrationTest.
 */
@ExtendWith(MockitoExtension.class)
class ContactAnalysisSchedulerTest {

    @Mock private ContactAnalysisService contactAnalysisService;
    @Mock private FarmRepository farmRepository;

    private ContactAnalysisScheduler scheduler;

    @BeforeEach
    void setUp() {
        scheduler = new ContactAnalysisScheduler(contactAnalysisService, farmRepository);
        ReflectionTestUtils.setField(scheduler, "enabled", true);
        ReflectionTestUtils.setField(scheduler, "analysisWindowHours", 72L);
    }

    private Farm farm(long id) {
        Farm f = new Farm();
        f.setId(id);
        return f;
    }

    @Test
    void analyzesEveryFarmWithWholeHerdScope() {
        when(farmRepository.findAll()).thenReturn(List.of(farm(1L), farm(2L), farm(3L)));
        when(contactAnalysisService.analyzeAndStore(any(Long.class), isNull(), any(Instant.class)))
                .thenReturn(4);

        ContactAnalysisScheduler.FarmAnalysisOutcome outcome = scheduler.runForAllFarms();

        assertThat(outcome.writtenByFarm()).containsOnlyKeys(1L, 2L, 3L);
        assertThat(outcome.writtenByFarm()).allSatisfy((farmId, written) -> assertThat(written).isEqualTo(4));
        assertThat(outcome.failedFarms()).isEmpty();
        verify(contactAnalysisService, times(3)).analyzeAndStore(any(Long.class), isNull(), any(Instant.class));
    }

    @Test
    void usesConfiguredRollingWindowAsCutoff() {
        when(farmRepository.findAll()).thenReturn(List.of(farm(7L)));
        ArgumentCaptor<Instant> cutoff = ArgumentCaptor.forClass(Instant.class);
        when(contactAnalysisService.analyzeAndStore(eq(7L), isNull(), cutoff.capture())).thenReturn(0);
        Instant before = Instant.now();

        scheduler.runForAllFarms();

        // One shared cutoff, ~72h in the past, computed at run start.
        Instant expectedCutoff = before.minus(Duration.ofHours(72));
        assertThat(cutoff.getValue()).isBetween(expectedCutoff.minusSeconds(5), expectedCutoff.plusSeconds(5));
    }

    @Test
    void singleFarmFailureDoesNotBlockRemainingFarms() {
        when(farmRepository.findAll()).thenReturn(List.of(farm(1L), farm(2L), farm(3L)));
        when(contactAnalysisService.analyzeAndStore(eq(1L), isNull(), any(Instant.class))).thenReturn(2);
        when(contactAnalysisService.analyzeAndStore(eq(2L), isNull(), any(Instant.class)))
                .thenThrow(new RuntimeException("boom"));
        when(contactAnalysisService.analyzeAndStore(eq(3L), isNull(), any(Instant.class))).thenReturn(5);

        ContactAnalysisScheduler.FarmAnalysisOutcome outcome = scheduler.runForAllFarms();

        assertThat(outcome.writtenByFarm())
                .containsOnlyKeys(1L, 3L)
                .containsEntry(1L, 2)
                .containsEntry(3L, 5);
        assertThat(outcome.failedFarms()).containsExactly(2L);
    }

    @Test
    void scheduledRunDelegatesToFarmsWhenEnabled() {
        when(farmRepository.findAll()).thenReturn(List.of(farm(9L)));
        when(contactAnalysisService.analyzeAndStore(eq(9L), isNull(), any(Instant.class))).thenReturn(1);

        scheduler.analyzeAllFarmsDaily();

        verify(contactAnalysisService).analyzeAndStore(eq(9L), isNull(), any(Instant.class));
    }

    @Test
    void disabledSwitchSkipsScheduledRun() {
        ReflectionTestUtils.setField(scheduler, "enabled", false);

        scheduler.analyzeAllFarmsDaily();

        verifyNoInteractions(contactAnalysisService, farmRepository);
        verify(contactAnalysisService, never()).analyzeAndStore(any(Long.class), isNull(), any(Instant.class));
    }
}
