package com.smartlivestock.health.domain.port;

import com.smartlivestock.health.domain.model.PhysiologyEventType;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Read-side physiology port (NIX-256). Merges two sources at read time —
 * manual {@code physiology_events} rows and {@code epidemic_dispositions}
 * (never written into this table) — into unified illness windows and derives
 * the lactation/dry stage from CALVING / DRY_OFF milestones.
 */
public interface PhysiologyQueryPort {

    /**
     * Illness windows of one livestock overlapping {@code [from, to)}.
     * Unpaired illness stays open-ended ({@code endedAt == null}).
     */
    List<PhysiologyWindow> activeWindows(Long livestockId, Instant from, Instant to);

    /** Batch variant per farm livestock id; avoids N+1 for herd queries. */
    Map<Long, List<PhysiologyWindow>> activeWindowsForFarm(Long farmId, Instant from, Instant to);

    /** Lactation/dry stage derived from the latest CALVING or DRY_OFF. */
    Optional<PhysiologyStage> currentStage(Long livestockId);

    /**
     * One illness window. {@code sourceType} is "MANUAL" for a manual
     * ILLNESS/RECOVERY pair ({@code refId == null}) or "DISPOSITION" when the
     * window is merged from {@code epidemic_dispositions} at read time
     * ({@code refId} is the disposition id).
     */
    record PhysiologyWindow(PhysiologyEventType eventType, Instant occurredAt, Instant endedAt,
                            String sourceType, Long refId) {}

    /** Current lifecycle stage with the instant it started. */
    record PhysiologyStage(PhysiologyStageType type, Instant since) {}

    enum PhysiologyStageType { LACTATING, DRY }
}
