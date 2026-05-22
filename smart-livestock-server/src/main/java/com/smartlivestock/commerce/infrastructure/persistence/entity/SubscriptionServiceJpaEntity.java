package com.smartlivestock.commerce.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.time.Instant;

@Entity
@Table(name = "subscription_services")
public class SubscriptionServiceJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "service_name", nullable = false, length = 100)
    private String serviceName;

    @Column(name = "service_key_prefix", length = 8)
    private String serviceKeyPrefix;

    @Column(name = "service_key_hash", nullable = false, length = 64)
    private String serviceKeyHash;

    @Column(name = "effective_tier", nullable = false, length = 20)
    private String effectiveTier;

    @Column(name = "device_quota")
    private Integer deviceQuota;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "last_heartbeat_at")
    private Instant lastHeartbeatAt;

    @Column(name = "grace_ends_at")
    private Instant graceEndsAt;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "heartbeat_interval_hrs")
    private Integer heartbeatIntervalHrs;

    @Column(name = "grace_period_days")
    private Integer gracePeriodDays;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    // --- Getters and Setters ---

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getServiceName() { return serviceName; }
    public void setServiceName(String serviceName) { this.serviceName = serviceName; }

    public String getServiceKeyPrefix() { return serviceKeyPrefix; }
    public void setServiceKeyPrefix(String serviceKeyPrefix) { this.serviceKeyPrefix = serviceKeyPrefix; }

    public String getServiceKeyHash() { return serviceKeyHash; }
    public void setServiceKeyHash(String serviceKeyHash) { this.serviceKeyHash = serviceKeyHash; }

    public String getEffectiveTier() { return effectiveTier; }
    public void setEffectiveTier(String effectiveTier) { this.effectiveTier = effectiveTier; }

    public Integer getDeviceQuota() { return deviceQuota; }
    public void setDeviceQuota(Integer deviceQuota) { this.deviceQuota = deviceQuota; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getLastHeartbeatAt() { return lastHeartbeatAt; }
    public void setLastHeartbeatAt(Instant lastHeartbeatAt) { this.lastHeartbeatAt = lastHeartbeatAt; }

    public Instant getGraceEndsAt() { return graceEndsAt; }
    public void setGraceEndsAt(Instant graceEndsAt) { this.graceEndsAt = graceEndsAt; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public Integer getHeartbeatIntervalHrs() { return heartbeatIntervalHrs; }
    public void setHeartbeatIntervalHrs(Integer heartbeatIntervalHrs) { this.heartbeatIntervalHrs = heartbeatIntervalHrs; }

    public Integer getGracePeriodDays() { return gracePeriodDays; }
    public void setGracePeriodDays(Integer gracePeriodDays) { this.gracePeriodDays = gracePeriodDays; }

    public Long getVersion() { return version; }
    public void setVersion(Long version) { this.version = version; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
