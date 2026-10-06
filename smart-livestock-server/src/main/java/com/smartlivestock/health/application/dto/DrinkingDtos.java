package com.smartlivestock.health.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * DTOs for the drinking-event marking loop (NIX-256 Task 3, spec §15.2).
 * {@code eventStartAt} is a wall-clock {@code "yyyy-MM-dd HH:mm"} string in
 * Asia/Shanghai; responses expose UTC instants.
 */
public final class DrinkingDtos {

    private DrinkingDtos() {}

    /** PATCH body: {label: "CONFIRMED"|"REJECTED"|"UNLABELED"}. */
    public record DrinkingLabelRequest(String label) {}

    /** POST body: {eventStartAt: "yyyy-MM-dd HH:mm", note?}. */
    public record DrinkingManualRequest(String eventStartAt, String note) {}

    /**
     * POST /api/v1/admin/drinking-recalculate body (NIX-256 Task 4):
     * {deviceId?, from: "yyyy-MM-dd", to: "yyyy-MM-dd"}. The window is a
     * <b>closed date range</b>: from 00:00 → to+1 day 00:00 (Asia/Shanghai).
     * Omitting deviceId recalculates every farm with active capsule
     * bindings (P5).
     */
    public record DrinkingRecalcRequest(Long deviceId, String from, String to) {}

    /**
     * Recalculation summary. {@code scope} is "DEVICE" (single device,
     * {@code farms} null) or "ALL_FARMS" (farm sweep; {@code failedFarms}
     * counts farms whose recalculation threw — the sweep continues past
     * them, mirroring the nightly batch semantics).
     */
    public record DrinkingRecalcResponse(String scope, Integer farms, int devices, int events, int failedFarms) {}

    /**
     * One drinking-event row. {@code lowConfidence} is a server-derived
     * flag: {@code confidence < health.drinking.low-confidence} (spec §15.2
     * "pending verification" marker); MANUAL rows carry confidence 1.0 and
     * never flag.
     */
    public record DrinkingEventResponse(
            Long id,
            Long livestockId,
            Long deviceId,
            Instant eventStartAt,
            Instant eventEndAt,
            BigDecimal tempDrop,
            BigDecimal minTemp,
            String source,
            String label,
            BigDecimal confidence,
            String algorithmVersion,
            String note,
            Instant createdAt,
            Instant updatedAt,
            boolean lowConfidence
    ) {}

    /**
     * One buffered fever window for the 48h chart's fever shadow region
     * (NIX-259 m-q): physiology illness windows ∪ TEMPERATURE_ABNORMAL
     * alert windows with the defervescence buffer already applied — the
     * same exclusion semantics the detector uses. Both bounds are
     * non-null: the server clips every window to the queried range before
     * serving it (open-ended windows end at the query's {@code to} bound)
     * so the client always renders a finite rectangle.
     */
    public record DrinkingFeverWindowResponse(Instant start, Instant end) {}

    /**
     * GET drinking-events response (NIX-259 m-q): event rows plus the
     * buffered fever windows overlapping the queried cow-day range. The
     * fever windows feed the 48h temperature × drinking chart's "fever
     * period excluded" shadow bands.
     */
    public record DrinkingEventListResponse(
            List<DrinkingEventResponse> events,
            List<DrinkingFeverWindowResponse> feverWindows
    ) {}

    // ════════════════════════════════════════════════════════════
    // Task 5a read endpoints — shapes pinned by the prototype data
    // tracing table (3c): every UI number maps onto a field below.
    // ════════════════════════════════════════════════════════════

    /**
     * GET drinking-summary response. {@code daily} is always present;
     * {@code weekly} only for {@code days=7}; {@code rolling30dBaseline}
     * only for {@code days=30} (independent computations, F4);
     * {@code dayCounts} (per-day count + fever coverage for the orange
     * fever-day bars) for days=7/30. All dates are Shanghai cow-days (F5).
     * {@code baselineMinDays} rides on every layer variant (days=1/7/30)
     * so the client's "baseline building n/{baselineMinDays}" chip reads
     * the server-side threshold (spec §4, F3 — no front-end mirror).
     */
    public record DrinkingSummaryResponse(
            LocalDate date,
            int days,
            DrinkingDaily daily,
            DrinkingWeekly weekly,
            DrinkingRollingBaseline rolling30dBaseline,
            List<DrinkingDayCount> dayCounts,
            int baselineMinDays
    ) {}

    /**
     * The {@code date} cow-day: counted events (§15.3 isCounted), their
     * timeline for the moment-distribution chart, and the end of the last
     * counted event (the client renders "35 min ago" from it).
     */
    public record DrinkingDaily(int count, List<DrinkingDayEvent> events, Instant lastDrinkEndAt) {}

    public record DrinkingDayEvent(Instant startAt, Instant endAt, BigDecimal tempDrop,
                                   String label, BigDecimal confidence, String source) {}

    /** Weekly sum counts fever days as-is (F4 layer 1: direct sum). */
    public record DrinkingWeekly(int count, BigDecimal avgPerDay) {}

    /**
     * Rolling 30-day baseline: average over sample days only (fever
     * coverage ≥50% days and under-reported days excluded, F4 layer 2).
     * {@code avgPerDay} is null when there is not a single sample day.
     */
    public record DrinkingRollingBaseline(BigDecimal avgPerDay, int sampleDays) {}

    /** One bar of the mini bar chart; fever-covered days render orange. */
    public record DrinkingDayCount(LocalDate date, int count, BigDecimal feverCoveredPercent) {}

    /**
     * GET drinking-peer-comparison response. {@code peerAvgPerDay} is null
     * with {@code reason=INSUFFICIENT_PEERS} when no other group member
     * reaches the minimum sample days (the UI shows the degraded copy, not
     * an error). {@code groupStage} is LACTATING / DRY or null when the
     * stage is undetermined.
     */
    public record DrinkingPeerComparisonResponse(
            BigDecimal peerAvgPerDay,
            String reason,
            String groupBreed,
            String groupStage,
            int peerCount,
            int sampleDaysTotal,
            int minSampleDays
    ) {}
}
