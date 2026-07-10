package com.smartlivestock.datagen.domain.model;

import org.junit.jupiter.api.Test;
import java.time.Instant;
import static org.junit.jupiter.api.Assertions.*;

class SynthesisScenarioTest {

    @Test
    void start_from_draft_succeeds() {
        SynthesisScenario s = new SynthesisScenario();
        s.setStatus(ScenarioStatus.DRAFT);
        s.start();
        assertEquals(ScenarioStatus.RUNNING, s.getStatus());
    }

    @Test
    void start_from_stopped_succeeds() {
        SynthesisScenario s = new SynthesisScenario();
        s.setStatus(ScenarioStatus.STOPPED);
        s.start();
        assertEquals(ScenarioStatus.RUNNING, s.getStatus());
    }

    @Test
    void start_from_running_fails() {
        SynthesisScenario s = new SynthesisScenario();
        s.setStatus(ScenarioStatus.RUNNING);
        assertThrows(IllegalStateException.class, s::start);
    }

    @Test
    void isActiveAt_within_window_true() {
        SynthesisScenario s = new SynthesisScenario();
        s.setStatus(ScenarioStatus.RUNNING);
        s.setWindowStart(Instant.parse("2026-01-01T00:00:00Z"));
        s.setWindowEnd(Instant.parse("2026-01-02T00:00:00Z"));
        assertTrue(s.isActiveAt(Instant.parse("2026-01-01T12:00:00Z")));
    }

    @Test
    void isActiveAt_exclusive_end() {
        SynthesisScenario s = new SynthesisScenario();
        s.setStatus(ScenarioStatus.RUNNING);
        s.setWindowStart(Instant.parse("2026-01-01T00:00:00Z"));
        s.setWindowEnd(Instant.parse("2026-01-02T00:00:00Z"));
        assertFalse(s.isActiveAt(Instant.parse("2026-01-02T00:00:00Z")));
    }

    @Test
    void isActiveAt_stopped_scenario_false() {
        SynthesisScenario s = new SynthesisScenario();
        s.setStatus(ScenarioStatus.STOPPED);
        s.setWindowStart(Instant.parse("2026-01-01T00:00:00Z"));
        s.setWindowEnd(Instant.parse("2026-01-02T00:00:00Z"));
        assertFalse(s.isActiveAt(Instant.parse("2026-01-01T12:00:00Z")));
    }
}
