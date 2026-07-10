package com.smartlivestock.datagen.domain.model;

import org.junit.jupiter.api.Test;
import java.time.Instant;
import static org.junit.jupiter.api.Assertions.*;

class GroundTruthLabelTest {

    @Test
    void overlaps_contained_range() {
        GroundTruthLabel l = new GroundTruthLabel();
        l.setPeriodStart(Instant.parse("2026-01-01T00:00:00Z"));
        l.setPeriodEnd(Instant.parse("2026-01-02T00:00:00Z"));
        assertTrue(l.overlaps(Instant.parse("2026-01-01T12:00:00Z"), Instant.parse("2026-01-01T18:00:00Z")));
    }

    @Test
    void overlaps_boundary_touching() {
        GroundTruthLabel l = new GroundTruthLabel();
        l.setPeriodStart(Instant.parse("2026-01-01T00:00:00Z"));
        l.setPeriodEnd(Instant.parse("2026-01-02T00:00:00Z"));
        assertTrue(l.overlaps(Instant.parse("2026-01-02T00:00:00Z"), Instant.parse("2026-01-03T00:00:00Z")));
    }

    @Test
    void no_overlap_completely_before() {
        GroundTruthLabel l = new GroundTruthLabel();
        l.setPeriodStart(Instant.parse("2026-01-02T00:00:00Z"));
        l.setPeriodEnd(Instant.parse("2026-01-03T00:00:00Z"));
        assertFalse(l.overlaps(Instant.parse("2026-01-01T00:00:00Z"), Instant.parse("2026-01-01T23:59:59Z")));
    }
}
