package com.smartlivestock.health.domain.service;

import java.time.Instant;
import java.util.Objects;

/**
 * Half-open exclusion interval {@code [start, end)} used by the individual
 * baseline learning kernel (plan 2026-11-03 Task 2).
 *
 * <p>A {@code null} {@code end} means the window stays open towards
 * infinity: every sample at or after {@code start} is covered. The kernel
 * buffers window ends (fever/illness buffer, drinking recovery) by producing
 * new immutable instances of this record.</p>
 */
public record BaselineExclusionWindow(Instant start, Instant end) {

    public BaselineExclusionWindow {
        Objects.requireNonNull(start, "start must not be null");
    }
}
