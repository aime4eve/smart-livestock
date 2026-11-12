package com.smartlivestock.ranch.application.dto;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.FenceZone;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

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
            Double deviceOnlineRate,
            Double inFenceRate,
            int noGpsCount,
            int outsideFenceCount
    ) {}

    public record SceneSummaryFever(int abnormalCount, int criticalCount) {}
    public record SceneSummaryDigestive(int abnormalCount, int watchCount) {}
    public record SceneSummaryEstrus(int highScoreCount) {}
    public record SceneSummaryEpidemic(double abnormalRate) {}

    /**
     * Calving scene counts (NIX-389): heads whose current snapshot
     * {@code calving_risk_score} sits in the alert band (>= 70) and the watch
     * band (50-69). Livestock without a snapshot row are never counted.
     */
    public record SceneSummaryCalving(int highRiskCount, int watchCount) {}

    /**
     * Subscription-gating state of the six health tiles (NIX-389): the server
     * is the single source of truth and ships one of three values per scene —
     * "OPEN" (gate unlocked), "LOCKED" (gate locked, platform policy
     * SHOW_LOCKED) or "HIDDEN" (gate locked, platform policy HIDE).
     */
    public record SceneSummaryGating(
            String fever,
            String digestive,
            String estrus,
            String epidemic,
            String ai,
            String calving
    ) {}

    public record SceneSummary(
            SceneSummaryFever fever,
            SceneSummaryDigestive digestive,
            SceneSummaryEstrus estrus,
            SceneSummaryEpidemic epidemic,
            // NIX-389 additive fields — appended so existing positional
            // consumers keep deserializing the original four scenes.
            SceneSummaryCalving calving,
            SceneSummaryGating gating
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
            int version,
            // Generation provenance echo (spec §4.3), same style as FenceDto:
            // stored JSON parsed to a Map, null/malformed degrades to null.
            Map<String, Object> generationMetadata
    ) {
        private static final Logger log = LoggerFactory.getLogger(FenceData.class);
        private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

        public static FenceData from(Fence fence, int livestockCount) {
            return new FenceData(
                    fence.getId(),
                    fence.getName(),
                    fence.isActive(),
                    "POLYGON",
                    fence.getColor(),
                    fence.getVertices(),
                    0.0,
                    livestockCount,
                    fence.getVersion(),
                    parseGenerationMetadata(fence.getId(), fence.getGenerationMetadata())
            );
        }

        /**
         * Echo the stored JSON metadata as a Map; degrade to null (never
         * throw) when the payload is absent or malformed so reads stay
         * safe. Mirrors FenceDto.parseGenerationMetadata.
         */
        private static Map<String, Object> parseGenerationMetadata(Long fenceId, String json) {
            if (json == null || json.isBlank()) {
                return null;
            }
            try {
                return OBJECT_MAPPER.readValue(json, new TypeReference<Map<String, Object>>() {});
            } catch (JsonProcessingException e) {
                log.warn("Failed to deserialize generation metadata for fence {}: {}", fenceId, e.getMessage());
                return null;
            }
        }
    }

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
            String primaryAlert,
            boolean hasHealthTicket   // NIX-245: red dot for livestock with open health tickets
    ) {}

    public record AlertData(
            Long id,
            String type,
            String severity,
            String status,
            String message,
            Long livestockId,
            Long fenceId,
            Long deviceId,
            String deviceCode,
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
