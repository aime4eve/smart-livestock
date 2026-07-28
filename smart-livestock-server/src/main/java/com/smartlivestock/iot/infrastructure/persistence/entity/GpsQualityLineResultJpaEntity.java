package com.smartlivestock.iot.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "gps_quality_line_results")
public class GpsQualityLineResultJpaEntity {

    @Id
    @Column(name = "test_id")
    private Long testId;

    @Column(name = "sample_count", nullable = false)
    private Integer sampleCount;

    @Column(name = "trip_count", nullable = false)
    private Integer tripCount;

    @Column(name = "mean_deviation_m", nullable = false, precision = 10, scale = 2)
    private BigDecimal meanDeviationM;

    @Column(name = "p50_m", nullable = false, precision = 10, scale = 2)
    private BigDecimal p50M;

    @Column(name = "p95_m", nullable = false, precision = 10, scale = 2)
    private BigDecimal p95M;

    @Column(name = "max_deviation_m", nullable = false, precision = 10, scale = 2)
    private BigDecimal maxDeviationM;

    @Column(name = "within15m_pct", nullable = false, precision = 5, scale = 1)
    private BigDecimal within15mPct;

    @Column(name = "within25m_pct", nullable = false, precision = 5, scale = 1)
    private BigDecimal within25mPct;

    @Column(name = "within40m_pct", nullable = false, precision = 5, scale = 1)
    private BigDecimal within40mPct;

    @Column(name = "grade", nullable = false, length = 12)
    private String grade;

    @Column(name = "first_recorded_at")
    private Instant firstRecordedAt;

    @Column(name = "last_recorded_at")
    private Instant lastRecordedAt;

    @Column(name = "computed_at", nullable = false)
    private Instant computedAt;

    @PrePersist
    protected void onCreate() {
        if (this.computedAt == null) this.computedAt = Instant.now();
    }

    public Long getTestId() { return testId; }
    public void setTestId(Long testId) { this.testId = testId; }
    public Integer getSampleCount() { return sampleCount; }
    public void setSampleCount(Integer sampleCount) { this.sampleCount = sampleCount; }
    public Integer getTripCount() { return tripCount; }
    public void setTripCount(Integer tripCount) { this.tripCount = tripCount; }
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
