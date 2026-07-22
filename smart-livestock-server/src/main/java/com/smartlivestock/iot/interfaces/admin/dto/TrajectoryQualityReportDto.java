package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.domain.model.QualityGrade;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * TRAJECTORY quality report (spec §6.4), assembled from the persisted
 * pairing snapshot (gps_quality_track_points), never re-querying gps_logs.
 */
public class TrajectoryQualityReportDto {

    private Long testId;
    private String deviceCode;
    private Instant startedAt;
    private Instant endedAt;
    private int toleranceSec;
    private QualityGrade grade;
    // pairing overview
    private int totalPoints;
    private int filePaired;
    private int logPaired;
    private int unpaired;
    private double pairRate;
    // absolute accuracy (FILE + GPS_LOG samples only)
    private double meanError;
    private double p50;
    private double p95;
    private double maxError;
    private List<TrackPoint> points;
    private StaticComparison staticComparison;

    /** One track point row; error is null when UNPAIRED. */
    public record TrackPoint(
        int sequenceNo,
        Instant collectedAt,
        BigDecimal rtkLatitude,
        BigDecimal rtkLongitude,
        BigDecimal deviceLatitude,
        BigDecimal deviceLongitude,
        Double error,
        String matchSource,
        Integer timeDiffSec
    ) {}

    /** Same-device static comparison; null when the device has no STATIC test. */
    public record StaticComparison(
        Long staticTestId,
        double staticP95,
        QualityGrade staticGrade,
        double deltaP95
    ) {}

    public Long getTestId() { return testId; }
    public void setTestId(Long testId) { this.testId = testId; }
    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }
    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }
    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }
    public int getToleranceSec() { return toleranceSec; }
    public void setToleranceSec(int toleranceSec) { this.toleranceSec = toleranceSec; }
    public QualityGrade getGrade() { return grade; }
    public void setGrade(QualityGrade grade) { this.grade = grade; }
    public int getTotalPoints() { return totalPoints; }
    public void setTotalPoints(int totalPoints) { this.totalPoints = totalPoints; }
    public int getFilePaired() { return filePaired; }
    public void setFilePaired(int filePaired) { this.filePaired = filePaired; }
    public int getLogPaired() { return logPaired; }
    public void setLogPaired(int logPaired) { this.logPaired = logPaired; }
    public int getUnpaired() { return unpaired; }
    public void setUnpaired(int unpaired) { this.unpaired = unpaired; }
    public double getPairRate() { return pairRate; }
    public void setPairRate(double pairRate) { this.pairRate = pairRate; }
    public double getMeanError() { return meanError; }
    public void setMeanError(double meanError) { this.meanError = meanError; }
    public double getP50() { return p50; }
    public void setP50(double p50) { this.p50 = p50; }
    public double getP95() { return p95; }
    public void setP95(double p95) { this.p95 = p95; }
    public double getMaxError() { return maxError; }
    public void setMaxError(double maxError) { this.maxError = maxError; }
    public List<TrackPoint> getPoints() { return points; }
    public void setPoints(List<TrackPoint> points) { this.points = points; }
    public StaticComparison getStaticComparison() { return staticComparison; }
    public void setStaticComparison(StaticComparison staticComparison) { this.staticComparison = staticComparison; }
}
