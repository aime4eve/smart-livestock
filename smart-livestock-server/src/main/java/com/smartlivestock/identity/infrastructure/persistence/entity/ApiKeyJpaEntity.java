package com.smartlivestock.identity.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "api_keys")
public class ApiKeyJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false) private Long tenantId;
    @Column(name = "key_name", nullable = false, length = 100) private String keyName;
    @Column(name = "key_hash", nullable = false, length = 64, unique = true) private String keyHash;
    @Column(name = "key_prefix", nullable = false, length = 20) private String keyPrefix;
    @Column(name = "role", length = 20) private String role;
    @Column(name = "status", nullable = false, length = 20) private String status = "ACTIVE";
    @Column(name = "expires_at") private Instant expiresAt;
    @Column(name = "last_used_at") private Instant lastUsedAt;
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @Column(name = "scopes", length = 500) private String scopes;
    @Column(name = "requests_per_minute") private Integer requestsPerMinute;
    @Column(name = "daily_quota") private Integer dailyQuota;
    @Column(name = "description", length = 500) private String description;

    @PrePersist protected void onCreate() { this.createdAt = Instant.now(); }

    public Long getId() { return id; } public void setId(Long id) { this.id = id; }
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
