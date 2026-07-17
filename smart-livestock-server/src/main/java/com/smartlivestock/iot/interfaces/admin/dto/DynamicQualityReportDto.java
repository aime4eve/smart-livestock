package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.port.dto.DynamicQualityStats;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Dynamic GPS quality report: route-driven matching results plus error distribution.
 * <p>
 * Returned by the dynamic report endpoint (test_type=DYNAMIC). Mirrors
 * {@link QualityReportDto} (static) but carries route-specific fields.
 */
public class DynamicQualityReportDto {

    private Long testId;
    private Long deviceId;
    private String deviceCode;
    private Long routeId;
    private String routeName;
    private Instant startedAt;
    private Instant endedAt;
    private double threshold;              // matching threshold used (meters)
    private QualityGrade grade;
    private DynamicQualityStats stats;
    // Per-route-point breakdown (ordered by sequenceNo)
    private List<PerRtkPointSummary> perPoint;
    // Matched samples detail (for map rendering)
    private List<MatchedPass> passes;
    // Static-vs-dynamic comparison (optional, same device)
    private StaticComparison staticComparison;

    public DynamicQualityReportDto() {
    }

    // --- Nested result records ---

    /** One route point's match outcome. */
    public record PerRtkPointSummary(
            Long rtkPointId,
            String locationName,
            String label,
            int sequenceNo,
            boolean passed,          // matched within threshold
            boolean ambiguous,       // shared GPS report with adjacent route point
            Double error,            // meters, null when not passed
            Instant matchedAt        // GPS report timestamp, null when not passed
    ) {
    }

    /** A matched GPS sample (for trajectory map rendering). */
    public record MatchedPass(
            int sequenceNo,
            BigDecimal latitude,
            BigDecimal longitude,
            BigDecimal rtkLatitude,
            BigDecimal rtkLongitude,
            double error,            // haversine distance to matched RTK point
            boolean ambiguous,
            Instant recordedAt
    ) {
    }

    /** Static-vs-dynamic comparison for the same device. */
    public record StaticComparison(
            Long staticTestId,
            double staticP95,
            QualityGrade staticGrade,
            double deltaP95          // dynamicP95 - staticP95 (negative = dynamic better)
    ) {
    }

    // --- Getters and Setters ---

    public Long getTestId() { return testId; }
    public void setTestId(Long testId) { this.testId = testId; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }

    public Long getRouteId() { return routeId; }
    public void setRouteId(Long routeId) { this.routeId = routeId; }

    public String getRouteName() { return routeName; }
    public void setRouteName(String routeName) { this.routeName = routeName; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }

    public double getThreshold() { return threshold; }
    public void setThreshold(double threshold) { this.threshold = threshold; }

    public QualityGrade getGrade() { return grade; }
    public void setGrade(QualityGrade grade) { this.grade = grade; }

    public DynamicQualityStats getStats() { return stats; }
    public void setStats(DynamicQualityStats stats) { this.stats = stats; }

    public List<PerRtkPointSummary> getPerPoint() { return perPoint; }
    public void setPerPoint(List<PerRtkPointSummary> perPoint) { this.perPoint = perPoint; }

    public List<MatchedPass> getPasses() { return passes; }
    public void setPasses(List<MatchedPass> passes) { this.passes = passes; }

    public StaticComparison getStaticComparison() { return staticComparison; }
    public void setStaticComparison(StaticComparison staticComparison) { this.staticComparison = staticComparison; }
}
