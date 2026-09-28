package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.application.signal.SignalRevisionService.FarmSignalRevision;
import com.smartlivestock.ranch.application.signal.SignalRevisionService.MapCursor;
import com.smartlivestock.ranch.application.signal.SignalStreamTicketService.TicketGrant;
import com.smartlivestock.ranch.infrastructure.signal.SignalStreamHub;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SignalStreamHubTest {

    @Mock
    private SignalRevisionService revisionService;

    private SignalStreamTicketService ticketService;
    private SignalStreamHub hub;

    @BeforeEach
    void setUp() {
        ticketService = new SignalStreamTicketService(
                Clock.fixed(Instant.parse("2026-09-28T00:00:00Z"), ZoneOffset.UTC),
                Duration.ofSeconds(30),
                Duration.ofMinutes(10)
        );
        hub = new SignalStreamHub(revisionService, 5);
    }

    @Test
    void connectsValidTicketAndEnforcesUserFarmLimit() {
        FarmSignalRevision revision = new FarmSignalRevision(
                1L, 2L, 3L, 4L, Instant.now()
        );
        when(revisionService.ensureFarm(1L)).thenReturn(revision);
        when(revisionService.validateMapCursor(revision, "2:3:4"))
                .thenReturn(new MapCursor(2L, 3L, 4L));

        for (int index = 0; index < 5; index++) {
            SseEmitter emitter = hub.connect(grant(), "2:3:4", null, index);
            assertThat(emitter).isNotNull();
            assertThat(hub.countUserFarmConnections(9L, 1L)).isEqualTo(index + 1);
        }

        assertThatThrownBy(() -> hub.connect(grant(), "2:3:4", null, 5))
                .isInstanceOf(IllegalStateException.class);
    }

    private TicketGrant grant() {
        TicketGrant grant = ticketService.issue(9L, 7L, 1L);
        return ticketService.consume(grant.ticket(), 9L, 7L, 1L, grant.streamToken());
    }
}
