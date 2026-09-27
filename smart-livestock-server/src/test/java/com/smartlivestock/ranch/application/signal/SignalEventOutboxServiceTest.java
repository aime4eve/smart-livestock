package com.smartlivestock.ranch.application.signal;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.infrastructure.persistence.SignalEventOutboxJpaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

@ExtendWith(MockitoExtension.class)
class SignalEventOutboxServiceTest {

    @Mock
    private SignalEventOutboxJpaRepository repository;

    private SignalEventOutboxService service;

    @BeforeEach
    void setUp() {
        service = new SignalEventOutboxService(repository, new ObjectMapper());
    }

    @Test
    void recordsOnlyFarmAndEntityChangeHint() {
        service.record(7L, SignalEventType.LIVESTOCK_POSITION_CHANGED, "LIVESTOCK", 12L);

        verify(repository).upsertPending(
                7L,
                "LIVESTOCK_POSITION_CHANGED",
                "LIVESTOCK",
                12L,
                "{\"farmId\":7,\"entityType\":\"LIVESTOCK\",\"entityId\":12}"
        );
    }

    @Test
    void rejectsIncompleteChangeHints() {
        assertThatThrownBy(() -> service.record(
                null, SignalEventType.ALERT_CHANGED, "ALERT", 1L))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.record(
                1L, null, "ALERT", 1L))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.record(
                1L, SignalEventType.ALERT_CHANGED, null, 1L))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.record(
                1L, SignalEventType.ALERT_CHANGED, "ALERT", null))
                .isInstanceOf(IllegalArgumentException.class);

        verifyNoInteractions(repository);
    }

    @Test
    void eventTypesContainPhaseTwoContract() {
        assertThat(SignalEventType.values()).extracting(Enum::name).containsExactlyInAnyOrder(
                "LIVESTOCK_POSITION_CHANGED",
                "RUMEN_METRIC_CHANGED",
                "ALERT_CHANGED",
                "FENCE_SIGNAL_CHANGED",
                "FENCE_GEOMETRY_CHANGED",
                "HEALTH_SIGNAL_CHANGED",
                "AI_ASSESSMENT_COMPLETED",
                "DEVICE_SIGNAL_CHANGED",
                "INSTALLATION_CHANGED",
                "LIVESTOCK_CHANGED"
        );
    }
}
