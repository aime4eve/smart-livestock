package com.smartlivestock.iot.domain.model;

import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

class TbDeviceBindingTest {

    private static final long NOW = 1_800_000_000_000L;

    private TbDeviceBinding binding(Long cursorMs, Instant lastPollAt, int failures) {
        TbDeviceBinding binding = new TbDeviceBinding();
        binding.setTelemetryCursorMs(cursorMs);
        binding.setLastPollAt(lastPollAt);
        binding.setConsecutiveFailures(failures);
        return binding;
    }

    @Test
    void healthyWhenCursorFreshAndFailuresBelowThreshold() {
        assertThat(binding(NOW - 60_000L, Instant.ofEpochMilli(NOW), 0)
                .isTbChannelHealthy(NOW, 900_000L, 3)).isTrue();
    }

    @Test
    void unhealthyWhenCursorFrozenBeyondStaleWindow() {
        assertThat(binding(NOW - 900_001L, Instant.ofEpochMilli(NOW), 0)
                .isTbChannelHealthy(NOW, 900_000L, 3)).isFalse();
    }

    @Test
    void unhealthyWhenFailuresReachThreshold() {
        assertThat(binding(NOW - 60_000L, Instant.ofEpochMilli(NOW), 3)
                .isTbChannelHealthy(NOW, 900_000L, 3)).isFalse();
    }

    @Test
    void fallsBackToLastPollBaselineWhenNeverPulled() {
        assertThat(binding(null, Instant.ofEpochMilli(NOW - 60_000L), 0)
                .isTbChannelHealthy(NOW, 900_000L, 3)).isTrue();
        assertThat(binding(null, Instant.ofEpochMilli(NOW - 900_001L), 0)
                .isTbChannelHealthy(NOW, 900_000L, 3)).isFalse();
    }

    @Test
    void benefitOfTheDoubtBeforeFirstPoll() {
        assertThat(binding(null, null, 0).isTbChannelHealthy(NOW, 900_000L, 3)).isTrue();
    }
}
