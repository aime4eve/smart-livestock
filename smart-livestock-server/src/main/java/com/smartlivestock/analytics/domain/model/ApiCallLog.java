package com.smartlivestock.analytics.domain.model;

import com.smartlivestock.shared.domain.Entity;
import java.time.Instant;

public class ApiCallLog extends Entity {
    private Long apiKeyId;
    private Long tenantId;
    private String endpoint;
    private String method;
    private int statusCode;
    private Integer responseTimeMs;
    private String ipAddress;
    private String userAgent;
    private Long farmId;
    private Instant requestedAt;

    public Long getApiKeyId() { return apiKeyId; } public void setApiKeyId(Long v) { apiKeyId = v; }
    public Long getTenantId() { return tenantId; } public void setTenantId(Long v) { tenantId = v; }
    public String getEndpoint() { return endpoint; } public void setEndpoint(String v) { endpoint = v; }
    public String getMethod() { return method; } public void setMethod(String v) { method = v; }
    public int getStatusCode() { return statusCode; } public void setStatusCode(int v) { statusCode = v; }
    public Integer getResponseTimeMs() { return responseTimeMs; } public void setResponseTimeMs(Integer v) { responseTimeMs = v; }
    public String getIpAddress() { return ipAddress; } public void setIpAddress(String v) { ipAddress = v; }
    public String getUserAgent() { return userAgent; } public void setUserAgent(String v) { userAgent = v; }
    public Long getFarmId() { return farmId; } public void setFarmId(Long v) { farmId = v; }
    public Instant getRequestedAt() { return requestedAt; } public void setRequestedAt(Instant v) { requestedAt = v; }
}
