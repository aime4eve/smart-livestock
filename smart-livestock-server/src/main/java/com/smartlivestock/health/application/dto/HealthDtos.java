package com.smartlivestock.health.application.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class HealthDtos {

    private HealthDtos() {}

    // ── Temperature ─────────────────────────────────────────────

    public record TemperatureReading(
            BigDecimal temperature,
            Instant timestamp
    ) {}

    public record FeverListItem(
            String livestockId,
            String livestockCode,
            String breed,
            BigDecimal baselineTemp,
            BigDecimal currentTemp,
            BigDecimal delta,
            String status,
            String conclusion
    ) {}

    public record FeverDetail(
            String livestockId,
            String livestockCode,
            BigDecimal baselineTemp,
            BigDecimal threshold,
            String status,
            String conclusion,
            List<TemperatureReading> recent72h
    ) {}

    public record FeverListResponse(
            List<FeverListItem> items
    ) {}

    // ── Digestive ───────────────────────────────────────────────

    public record MotilityReading(
            BigDecimal frequency,
            BigDecimal intensity,
            Instant timestamp
    ) {}

    public record DigestiveListItem(
            String livestockId,
            String livestockCode,
            String breed,
            BigDecimal motilityBaseline,
            BigDecimal currentFrequency,
            String status,
            String advice
    ) {}

    public record DigestiveDetail(
            String livestockId,
            String livestockCode,
            BigDecimal motilityBaseline,
            String status,
            String advice,
            List<MotilityReading> recent24h
    ) {}

    public record DigestiveListResponse(
            List<DigestiveListItem> items
    ) {}

    // ── Estrus ──────────────────────────────────────────────────

    public record EstrusTrendPoint(
            int score,
            Instant timestamp
    ) {}

    public record EstrusListItem(
            String livestockId,
            String livestockCode,
            String breed,
            String gender,
            int score,
            Integer stepIncreasePercent,
            BigDecimal tempDelta,
            BigDecimal distanceDelta,
            Instant timestamp,
            String advice
    ) {}

    public record EstrusDetail(
            String livestockId,
            String livestockCode,
            int score,
            Integer stepIncreasePercent,
            BigDecimal tempDelta,
            BigDecimal distanceDelta,
            Instant timestamp,
            String advice,
            List<EstrusTrendPoint> trend7d
    ) {}

    public record EstrusListResponse(
            List<EstrusListItem> items
    ) {}

    // ── Epidemic ────────────────────────────────────────────────

    public record HerdHealthMetrics(
            BigDecimal avgTemperature,
            BigDecimal avgActivity,
            BigDecimal abnormalRate,
            int totalLivestock,
            int abnormalCount
    ) {}

    public record ContactTraceItem(
            String fromId,
            String fromCode,
            String toId,
            String toCode,
            BigDecimal proximity,
            Instant lastContact
    ) {}

    public record EpidemicResponse(
            HerdHealthMetrics metrics,
            List<ContactTraceItem> contacts,
            String riskLevel
    ) {}

    // ── Overview ────────────────────────────────────────────────

    public record HealthOverviewStats(
            int totalLivestock,
            double healthyRate,
            int alertCount,
            int criticalCount,
            double deviceOnlineRate,
            String healthTrend,
            String livestockTrend
    ) {}

    public record SceneSummaryFever(int abnormalCount, int criticalCount) {}
    public record SceneSummaryDigestive(int abnormalCount, int watchCount) {}
    public record SceneSummaryEstrus(int highScoreCount, boolean breedingAdvice) {}
    public record SceneSummaryEpidemic(String status, double abnormalRate) {}

    public record SceneSummary(
            SceneSummaryFever fever,
            SceneSummaryDigestive digestive,
            SceneSummaryEstrus estrus,
            SceneSummaryEpidemic epidemic
    ) {}

    public record PendingTask(
            String id,
            String title,
            String subtitle,
            String routePath,
            String severity
    ) {}

    public record HealthOverviewResponse(
            HealthOverviewStats stats,
            SceneSummary sceneSummary,
            List<PendingTask> pendingTasks
    ) {}
}
