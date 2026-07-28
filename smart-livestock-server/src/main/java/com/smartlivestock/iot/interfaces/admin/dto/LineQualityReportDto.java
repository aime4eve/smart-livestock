package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.domain.model.QualityGrade;

import java.time.Instant;

/**
 * LINE quality report summary (NIX-68, spec §7.4): statistics only, read from
 * the result snapshot. The track point list and per-point deviations are
 * served by the /track and /deviations sub-endpoints (response size control).
 */
public class LineQualityReportDto {

    private Long testId;
    private String deviceCode;
    private Instant startedAt;
    private Instant endedAt;
    private Long trackLineId;
    private String trackLineName;
    private QualityGrade grade;
    private int sampleCount;
    private int tripCount;
    private double meanDeviation;
    private double p50;
    private double p95;
    private double maxDeviation;
    private double within15mPct;
    private double within25mPct;
    private double within40mPct;

    public Long getTestId() { return testId; }
    public void setTestId(Long testId) { this.testId = testId; }
    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }
    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }
    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }
    public Long getTrackLineId() { return trackLineId; }
    public void setTrackLineId(Long trackLineId) { this.trackLineId = trackLineId; }
    public String getTrackLineName() { return trackLineName; }
    public void setTrackLineName(String trackLineName) { this.trackLineName = trackLineName; }
    public QualityGrade getGrade() { return grade; }
    public void setGrade(QualityGrade grade) { this.grade = grade; }
    public int getSampleCount() { return sampleCount; }
    public void setSampleCount(int sampleCount) { this.sampleCount = sampleCount; }
    public int getTripCount() { return tripCount; }
    public void setTripCount(int tripCount) { this.tripCount = tripCount; }
    public double getMeanDeviation() { return meanDeviation; }
    public void setMeanDeviation(double meanDeviation) { this.meanDeviation = meanDeviation; }
    public double getP50() { return p50; }
    public void setP50(double p50) { this.p50 = p50; }
    public double getP95() { return p95; }
    public void setP95(double p95) { this.p95 = p95; }
    public double getMaxDeviation() { return maxDeviation; }
    public void setMaxDeviation(double maxDeviation) { this.maxDeviation = maxDeviation; }
    public double getWithin15mPct() { return within15mPct; }
    public void setWithin15mPct(double within15mPct) { this.within15mPct = within15mPct; }
    public double getWithin25mPct() { return within25mPct; }
    public void setWithin25mPct(double within25mPct) { this.within25mPct = within25mPct; }
    public double getWithin40mPct() { return within40mPct; }
    public void setWithin40mPct(double within40mPct) { this.within40mPct = within40mPct; }
}
