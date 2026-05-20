package com.smartlivestock.commerce.application.dto;

public class QuotaResult {

    private final boolean allowed;
    private final String reason;
    private final Integer retentionDays;

    private QuotaResult(boolean allowed, String reason, Integer retentionDays) {
        this.allowed = allowed;
        this.reason = reason;
        this.retentionDays = retentionDays;
    }

    public static QuotaResult allowed() {
        return new QuotaResult(true, null, null);
    }

    public static QuotaResult denied(String reason) {
        return new QuotaResult(false, reason, null);
    }

    public static QuotaResult allowedWithRetention(int days) {
        return new QuotaResult(true, null, days);
    }

    public boolean isAllowed() { return allowed; }
    public String getReason() { return reason; }
    public Integer getRetentionDays() { return retentionDays; }
}
