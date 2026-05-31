package com.smartlivestock.analytics.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "api_usage_daily")
public class ApiUsageDailyJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "api_key_id", nullable = false) private Long apiKeyId;
    @Column(name = "tenant_id", nullable = false) private Long tenantId;
    @Column(name = "usage_date", nullable = false) private LocalDate usageDate;
    @Column(name = "total_calls", nullable = false) private int totalCalls;
    @Column(name = "success_calls", nullable = false) private int successCalls;
    @Column(name = "error_calls", nullable = false) private int errorCalls;
    @Column(name = "avg_response_ms") private Integer avgResponseMs;
    @Column(name = "p95_response_ms") private Integer p95ResponseMs;
    @Column(name = "top_endpoints", columnDefinition = "jsonb") private String topEndpoints;

    public Long getId() { return id; } public void setId(Long v) { id = v; }
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
