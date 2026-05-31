package com.smartlivestock.analytics.domain.model;

import com.smartlivestock.shared.domain.Entity;
import java.time.LocalDate;

public class ApiUsageDaily extends Entity {
    private Long apiKeyId;
    private Long tenantId;
    private LocalDate usageDate;
    private int totalCalls;
    private int successCalls;
    private int errorCalls;
    private Integer avgResponseMs;
    private Integer p95ResponseMs;
    private String topEndpoints; // JSON string

    public Long getApiKeyId() { return apiKeyId; } public void setApiKeyId(Long v) { apiKeyId = v; }
    public Long getTenantId() { return tenantId; } public void setTenantId(Long v) { tenantId = v; }
    public LocalDate getUsageDate() { return usageDate; } public void setUsageDate(LocalDate v) { usageDate = v; }
    public int getTotalCalls() { return totalCalls; } public void setTotalCalls(int v) { totalCalls = v; }
    public int getSuccessCalls() { return successCalls; } public void setSuccessCalls(int v) { successCalls = v; }
    public int getErrorCalls() { return errorCalls; } public void setErrorCalls(int v) { errorCalls = v; }
    public Integer getAvgResponseMs() { return avgResponseMs; } public void setAvgResponseMs(Integer v) { avgResponseMs = v; }
    public Integer getP95ResponseMs() { return p95ResponseMs; } public void setP95ResponseMs(Integer v) { p95ResponseMs = v; }
    public String getTopEndpoints() { return topEndpoints; } public void setTopEndpoints(String v) { topEndpoints = v; }
}
