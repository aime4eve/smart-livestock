package com.smartlivestock.identity.domain.model;

import com.smartlivestock.shared.domain.Entity;
import java.time.Instant;

public class ApiKey extends Entity {
    private Long tenantId;
    private String keyName;
    private String keyHash;
    private String keyPrefix;
    private String role;
    private String status = "ACTIVE";
    private Instant expiresAt;
    private Instant lastUsedAt;
    private Instant createdAt;
    private String scopes;
    private Integer requestsPerMinute;
    private Integer dailyQuota;
    private String description;

    public ApiKey() {}

    public boolean isExpired() {
        return expiresAt != null && Instant.now().isAfter(expiresAt);
    }

    public boolean isActive() {
        return "ACTIVE".equals(status) && !isExpired();
    }

    public Long getTenantId() { return tenantId; } public void setTenantId(Long v) { tenantId = v; }
    public String getKeyName() { return keyName; } public void setKeyName(String v) { keyName = v; }
    public String getKeyHash() { return keyHash; } public void setKeyHash(String v) { keyHash = v; }
    public String getKeyPrefix() { return keyPrefix; } public void setKeyPrefix(String v) { keyPrefix = v; }
    public String getRole() { return role; } public void setRole(String v) { role = v; }
    public String getStatus() { return status; } public void setStatus(String v) { status = v; }
    public Instant getExpiresAt() { return expiresAt; } public void setExpiresAt(Instant v) { expiresAt = v; }
    public Instant getLastUsedAt() { return lastUsedAt; } public void setLastUsedAt(Instant v) { lastUsedAt = v; }
    public Instant getCreatedAt() { return createdAt; } public void setCreatedAt(Instant v) { createdAt = v; }
    public String getScopes() { return scopes; } public void setScopes(String v) { scopes = v; }
    public Integer getRequestsPerMinute() { return requestsPerMinute; } public void setRequestsPerMinute(Integer v) { requestsPerMinute = v; }
    public Integer getDailyQuota() { return dailyQuota; } public void setDailyQuota(Integer v) { dailyQuota = v; }
    public String getDescription() { return description; } public void setDescription(String v) { description = v; }
}
