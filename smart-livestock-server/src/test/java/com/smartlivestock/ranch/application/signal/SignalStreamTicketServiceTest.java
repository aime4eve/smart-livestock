package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class SignalStreamTicketServiceTest {

    private MutableClock clock;
    private SignalStreamTicketService service;

    @BeforeEach
    void setUp() {
        clock = new MutableClock(Instant.parse("2026-09-28T00:00:00Z"));
        service = new SignalStreamTicketService(
                clock, Duration.ofSeconds(30), Duration.ofMinutes(10)
        );
    }

    @Test
    void validTicketConsumesOnceAndBindsUserTenantFarm() {
        var grant = service.issue(9L, 1L, 2L);

        assertThat(grant.consumed()).isFalse();
        assertThat(service.consume(
                grant.ticket(), 2L, grant.streamToken(), false
        ).userId()).isEqualTo(9L);
        assertThat(grant.consumed()).isTrue();

        assertThatThrownBy(() -> service.consume(
                grant.ticket(), 2L, "different-cookie", true
        )).isInstanceOf(ApiException.class);
    }

    @Test
    void crossFarmReplayIsRejected() {
        var grant = service.issue(9L, 1L, 2L);

        assertThatThrownBy(() -> service.consume(
                grant.ticket(), 9L, 1L, 3L, grant.streamToken()
        )).isInstanceOf(ApiException.class);
        assertThat(grant.consumed()).isFalse();
    }

    @Test
    void expiredTicketIsRejected() {
        var grant = service.issue(9L, 1L, 2L);
        clock.advance(Duration.ofSeconds(31));

        assertThatThrownBy(() -> service.consume(
                grant.ticket(), 9L, 1L, 2L, grant.streamToken()
        )).isInstanceOf(ApiException.class);
    }

    @Test
    void browserReconnectUsesCookieWithoutReusingConsumedTicket() {
        var grant = service.issue(9L, 1L, 2L);
        service.consume(grant.ticket(), 9L, 1L, 2L, grant.streamToken());

        var reconnect = service.reconnect(
                grant.streamToken(), 9L, 1L, 2L
        );
        assertThat(reconnect.ticket()).isEqualTo(grant.ticket());

        assertThatThrownBy(() -> service.reconnect(
                grant.streamToken(), 10L, 1L, 2L
        )).isInstanceOf(ApiException.class);
    }

    private static final class MutableClock extends Clock {
        private Instant instant;

        private MutableClock(Instant instant) {
            this.instant = instant;
        }

        private void advance(Duration duration) {
            instant = instant.plus(duration);
        }

        @Override
        public ZoneOffset getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return instant;
        }
    }
}
