package com.smartlivestock.analytics.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "api_call_logs")
public class ApiCallLogJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "api_key_id") private Long apiKeyId;
    @Column(name = "tenant_id", nullable = false) private Long tenantId;
    @Column(name = "endpoint", nullable = false, length = 200) private String endpoint;
    @Column(name = "method", nullable = false, length = 10) private String method;
    @Column(name = "status_code", nullable = false) private int statusCode;
    @Column(name = "response_time_ms") private Integer responseTimeMs;
    @Column(name = "ip_address", length = 45) private String ipAddress;
    @Column(name = "user_agent", length = 500) private String userAgent;
    @Column(name = "farm_id") private Long farmId;
    @Column(name = "requested_at", nullable = false) private Instant requestedAt;

    public Long getId() { return id; } public void setId(Long v) { id = v; }
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
