package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Aggregated result snapshot of one LINE test (NIX-68, spec §6.5, D4):
 * statistics and grade computed at test creation. Snapshotted (not recomputed)
 * because DataRetentionService purges the underlying gps_logs rows.
 */
public class GpsQualityLineResult {

    private Long testId;
    private Integer sampleCount;
    private BigDecimal meanDeviationM;
    private BigDecimal p50M;
    private BigDecimal p95M;
    private BigDecimal maxDeviationM;
    private BigDecimal within15mPct;
    private BigDecimal within25mPct;
    private BigDecimal within40mPct;
    private String grade;
    private Instant firstRecordedAt;
    private Instant lastRecordedAt;
    private Instant computedAt;

    public Long getTestId() { return testId; }
    public void setTestId(Long testId) { this.testId = testId; }
    public Integer getSampleCount() { return sampleCount; }
    public void setSampleCount(Integer sampleCount) { this.sampleCount = sampleCount; }
    public BigDecimal getMeanDeviationM() { return meanDeviationM; }
    public void setMeanDeviationM(BigDecimal meanDeviationM) { this.meanDeviationM = meanDeviationM; }
    public BigDecimal getP50M() { return p50M; }
    public void setP50M(BigDecimal p50M) { this.p50M = p50M; }
    public BigDecimal getP95M() { return p95M; }
    public void setP95M(BigDecimal p95M) { this.p95M = p95M; }
    public BigDecimal getMaxDeviationM() { return maxDeviationM; }
    public void setMaxDeviationM(BigDecimal maxDeviationM) { this.maxDeviationM = maxDeviationM; }
    public BigDecimal getWithin15mPct() { return within15mPct; }
    public void setWithin15mPct(BigDecimal within15mPct) { this.within15mPct = within15mPct; }
    public BigDecimal getWithin25mPct() { return within25mPct; }
    public void setWithin25mPct(BigDecimal within25mPct) { this.within25mPct = within25mPct; }
    public BigDecimal getWithin40mPct() { return within40mPct; }
    public void setWithin40mPct(BigDecimal within40mPct) { this.within40mPct = within40mPct; }
    public String getGrade() { return grade; }
    public void setGrade(String grade) { this.grade = grade; }
    public Instant getFirstRecordedAt() { return firstRecordedAt; }
    public void setFirstRecordedAt(Instant firstRecordedAt) { this.firstRecordedAt = firstRecordedAt; }
    public Instant getLastRecordedAt() { return lastRecordedAt; }
    public void setLastRecordedAt(Instant lastRecordedAt) { this.lastRecordedAt = lastRecordedAt; }
    public Instant getComputedAt() { return computedAt; }
    public void setComputedAt(Instant computedAt) { this.computedAt = computedAt; }
}
