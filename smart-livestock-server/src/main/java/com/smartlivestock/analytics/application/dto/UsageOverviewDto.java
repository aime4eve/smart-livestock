package com.smartlivestock.analytics.application.dto;

import java.time.LocalDate;

public class UsageOverviewDto {
    private Long totalCalls;
    private Long successCalls;
    private Long errorCalls;
    private Double avgResponseMs;
    private LocalDate from;
    private LocalDate to;

    public UsageOverviewDto(Long totalCalls, Long successCalls, Long errorCalls,
                            Double avgResponseMs, LocalDate from, LocalDate to) {
        this.totalCalls = totalCalls;
        this.successCalls = successCalls;
        this.errorCalls = errorCalls;
        this.avgResponseMs = avgResponseMs;
        this.from = from;
        this.to = to;
    }

    public Long getTotalCalls() { return totalCalls; }
    public Long getSuccessCalls() { return successCalls; }
    public Long getErrorCalls() { return errorCalls; }
    public Double getAvgResponseMs() { return avgResponseMs; }
    public LocalDate getFrom() { return from; }
    public LocalDate getTo() { return to; }
}
