package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.FenceZone;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * Aggregated ranch overview response combining fences, livestock health,
 * alerts, and scene summaries into a single payload.
 */
public final class RanchOverviewDto {

    private RanchOverviewDto() {}

    public record OverallStats(
            int totalLivestock,
            Double healthyRate,
            int alertCount,
            int criticalCount,
            double deviceOnlineRate,
            Double inFenceRate
    ) {}

    public record SceneSummaryFever(int abnormalCount, int criticalCount) {}
    public record SceneSummaryDigestive(int abnormalCount, int watchCount) {}
    public record SceneSummaryEstrus(int highScoreCount) {}
    public record SceneSummaryEpidemic(double abnormalRate) {}

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

    public record FenceData(
            Long id,
            String name,
            boolean active,
            String type,
            String color,
            List<GpsCoordinate> points,
            double areaHectares,
            int livestockCount,
            int version
    ) {}

    public record FenceZoneData(
            Long id,
            Long fenceId,
            String name,
            String zoneType,
            List<GpsCoordinate> vertices,
            int alertRadius,
            String severity,
            boolean active
    ) {
        public static FenceZoneData from(FenceZone zone) {
            return new FenceZoneData(
                    zone.getId(),
                    zone.getFenceId(),
                    zone.getName(),
                    zone.getZoneType(),
                    zone.getVertices(),
                    zone.getAlertRadius(),
                    zone.getSeverity(),
                    zone.isActive()
            );
        }
    }

    public record LivestockMarker(
            String livestockId,
            String livestockCode,
            BigDecimal latitude,
            BigDecimal longitude,
            String healthStatus,
            String primaryAlert
    ) {}

    public record AlertData(
            Long id,
            String type,
            String severity,
            String status,
            String message,
            Long livestockId,
            Long fenceId,
            Instant occurredAt,
            boolean read,
            String resolvedType,
            Instant resolvedAt,
            Double distance,
            String direction
    ) {}

    public record RanchOverviewResponse(
            OverallStats overallStats,
            SceneSummary sceneSummary,
            List<PendingTask> pendingTasks,
            List<FenceData> fences,
            List<LivestockMarker> livestockMarkers,
            List<AlertData> alerts,
            Map<String, Integer> fenceAlertSummary,
            Map<String, Integer> healthAlertSummary,
            List<FenceZoneData> fenceZones
    ) {}
}
