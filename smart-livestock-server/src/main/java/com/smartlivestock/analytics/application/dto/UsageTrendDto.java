package com.smartlivestock.analytics.application.dto;

import java.time.LocalDate;

public class UsageTrendDto {
    private LocalDate date;
    private int totalCalls;
    private int successCalls;
    private int errorCalls;
    private Integer avgResponseMs;

    public UsageTrendDto(LocalDate date, int totalCalls, int successCalls,
                         int errorCalls, Integer avgResponseMs) {
        this.date = date;
        this.totalCalls = totalCalls;
        this.successCalls = successCalls;
        this.errorCalls = errorCalls;
        this.avgResponseMs = avgResponseMs;
    }

    public LocalDate getDate() { return date; }
    public int getTotalCalls() { return totalCalls; }
    public int getSuccessCalls() { return successCalls; }
    public int getErrorCalls() { return errorCalls; }
    public Integer getAvgResponseMs() { return avgResponseMs; }
}
