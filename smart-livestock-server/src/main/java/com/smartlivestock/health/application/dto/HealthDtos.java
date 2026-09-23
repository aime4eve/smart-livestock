package com.smartlivestock.health.application.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

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
           List<TemperatureReading> recent72h,
           AiAnomalySummary aiAnomaly
   ) {}

    public record FeverListResponse(
            List<FeverListItem> items
    ) {}

    // ── Digestive ───────────────────────────────────────────────

    public record MotilityReading(
            BigDecimal frequency,
            BigDecimal intensity,
            Long rawCounter,
            Long counterDelta,
            String source,
            Instant timestamp
    ) {}

    public record DeviceHealthSeries(
            String deviceId,
            List<TemperatureReading> temperature72h,
            List<MotilityReading> motility24h
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
           List<MotilityReading> recent24h,
           AiAnomalySummary aiAnomaly
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
           List<EstrusTrendPoint> trend7d,
           AiAnomalySummary aiAnomaly
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
            Double healthyRate,
            int alertCount,
            int criticalCount,
            double deviceOnlineRate,
            String healthTrend,
            String livestockTrend,
            int aiAnomalyCount,
            double avgAiAnomalyScore
    ) {}

    public record SceneSummaryFever(int abnormalCount, int criticalCount, int activeAlertCount) {}
    public record SceneSummaryDigestive(int abnormalCount, int watchCount, int activeAlertCount) {}
    public record SceneSummaryEstrus(int highScoreCount, boolean breedingAdvice, int activeAlertCount) {}
    public record SceneSummaryEpidemic(String status, double abnormalRate, int activeAlertCount) {}
    public record SceneSummaryAi(int anomalyCount, int highScoreCount, double avgScore, int activeAlertCount) {}

    public record SceneSummary(
            SceneSummaryFever fever,
            SceneSummaryDigestive digestive,
            SceneSummaryEstrus estrus,
            SceneSummaryEpidemic epidemic,
            SceneSummaryAi ai
    ) {}

    // ── Health episodes (NIX-245 workbenches) ────────────────────

    /**
     * One workbench row: current scene state + its open ticket + AI view.
     * Severity/band values are codes — the frontend maps them to localized
     * plain-language labels (spec §6, "界面说人话").
     */
    public record EpisodeRow(
            Long livestockId,
            String livestockCode,
            String statusLevel,        // critical | warning | watch | normal
            Double currentValue,       // °C / motility freq / estrus score per scene
            Double baseline,
            Double durationHours,      // from the open ticket's createdAt
            String trend,              // up | down | flat (fever scene only)
            double aiScore,
            String aiBand,             // calm | watch | alarm (AiHealthBands)
            String aiFindingCode,      // temp_spike | rhythm_off | multi_shift | none
            java.time.Instant aiAssessedAt,
            int activeAlertCount,
            String alertSeverity,      // CRITICAL | WARNING | null
            boolean unread
    ) {}

    public record EpisodeBoard(
            String scene,              // fever | digestive | estrus | epidemic
            int totalLivestock,
            int abnormalCount,
            int activeAlertCount,
            boolean reconciled,        // abnormalCount == activeAlertCount
            double epidemicRate,       // epidemic scene only, else 0
            List<EpisodeRow> abnormal,
            List<EpisodeRow> recoveredToday,
            List<EpisodeRow> normal
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

    // ── Health Detail Charts (subscription-gated) ──────────────

    public record DailyFeverHour(String date, double hours) {}

    public record IntensityCell(int hour, double intensity, boolean abnormal) {}

    public record ActivityComparisonData(
            int recentSteps, int baselineSteps,
            double recentDistance, double baselineDistance,
            double recentActivityIndex, double baselineActivityIndex
    ) {}

    public record ContactNode(
            String livestockId, String livestockCode,
            double proximityMeters, int contactDurationMinutes,
            Instant lastContactAt, int hoursAgo,
            int timeScore, int distanceScore, int durationScore,
            int totalRiskScore, String riskLevel
    ) {}

    public record ContactNetworkResponse(
            String sourceLivestockId, String sourceLivestockCode,
            String diseaseType, Instant markedAt,
            List<ContactNode> contacts
    ) {}

    public record MarkDiseaseRequest(
            Long livestockId, String diseaseType
    ) {}

// ── Stats / Trends ─────────────────────────────────────────

    public record StatsTrendPoint(String date, double value) {}

    public record StatsSummary(
            int totalLivestock,
            Double healthyRate,
            int alertCount,
            int criticalCount,
            double avgTemperature,
            double avgMotility
    ) {}

    public record StatsResponse(
            StatsSummary summary,
            List<StatsTrendPoint> temperatureTrend,
            List<StatsTrendPoint> healthRateTrend,
            List<StatsTrendPoint> alertTrend,
           Map<String, Integer> healthDistribution
   ) {}

   public record AiAnomalySummary(
           Double anomalyScore,
           String anomalyType,
           Integer nEff,
           String capabilityUsed,
           Instant assessedAt
   ) {}
}
