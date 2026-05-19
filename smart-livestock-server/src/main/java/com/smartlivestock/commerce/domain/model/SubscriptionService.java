package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.commerce.domain.model.event.ServiceActivatedEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceHeartbeatLostEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceHeartbeatRecoveredEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceProvisionedEvent;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;
import com.smartlivestock.shared.domain.event.ServiceDegradedEvent;
import com.smartlivestock.shared.domain.event.ServiceQuotaAdjustedEvent;
import com.smartlivestock.shared.domain.event.ServiceRevokedEvent;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;

/**
 * SubscriptionService aggregate root managing licensed service lifecycle.
 * <p>
 * State machine:
 * PROVISIONED -> ACTIVE -> GRACE_PERIOD -> DEGRADED -> EXPIRED
 *            |-> EXPIRED (revoke/expire)
 * <p>
 * MVP activation mechanism: offline License file.
 * provision() hashes the service key; activate() transitions state.
 * JWT License file generation is done at the application service layer.
 */
public class SubscriptionService extends AggregateRoot {

    private Long tenantId;
    private String serviceName;
    private String serviceKeyPrefix;
    private String serviceKeyHash;
    private SubscriptionTier effectiveTier;
    private Integer deviceQuota;
    private SubscriptionServiceStatus status;
    private Instant lastHeartbeatAt;
    private Instant graceEndsAt;
    private Instant startedAt;
    private Instant expiresAt;
    private int heartbeatIntervalHrs = 24;
    private int gracePeriodDays = 7;

    /** No-arg constructor for JPA. */
    public SubscriptionService() {
    }

    // ── Factory methods ──────────────────────────────────────────────

    /**
     * Provision a new licensed service for a tenant.
     *
     * @param tenantId      the tenant identifier
     * @param serviceName   service name (e.g. "gps-tracking")
     * @param rawServiceKey the raw service key to hash and store
     * @param tier          the effective subscription tier
     * @param deviceQuota   device quota (may be null for unlimited)
     * @return new SubscriptionService in PROVISIONED status
     */
    public static SubscriptionService provision(Long tenantId, String serviceName,
                                                 String rawServiceKey,
                                                 SubscriptionTier tier, Integer deviceQuota) {
        SubscriptionService svc = new SubscriptionService();
        svc.tenantId = tenantId;
        svc.serviceName = serviceName;
        svc.serviceKeyPrefix = rawServiceKey.substring(0, Math.min(rawServiceKey.length(), 8));
        svc.serviceKeyHash = sha256Hex(rawServiceKey);
        svc.effectiveTier = tier;
        svc.deviceQuota = deviceQuota;
        svc.status = SubscriptionServiceStatus.PROVISIONED;
        svc.startedAt = Instant.now();
        svc.registerEvent(new ServiceProvisionedEvent(tenantId, serviceName));
        return svc;
    }

    // ── State transitions ────────────────────────────────────────────

    /**
     * Activate the service (from PROVISIONED).
     * Sets the initial heartbeat timestamp.
     */
    public void activate(Instant expiresAt) {
        requireStatus(SubscriptionServiceStatus.PROVISIONED, "activate");
        this.expiresAt = expiresAt;
        this.lastHeartbeatAt = Instant.now();
        this.status = SubscriptionServiceStatus.ACTIVE;
        registerEvent(new ServiceActivatedEvent(tenantId, serviceName));
    }

    /**
     * Record a heartbeat. Allowed from ACTIVE or GRACE_PERIOD.
     * Recovers from GRACE_PERIOD back to ACTIVE.
     */
    public void recordHeartbeat() {
        requireStatusFor("recordHeartbeat",
            SubscriptionServiceStatus.ACTIVE, SubscriptionServiceStatus.GRACE_PERIOD);
        boolean wasGracePeriod = this.status == SubscriptionServiceStatus.GRACE_PERIOD;
        this.lastHeartbeatAt = Instant.now();
        this.status = SubscriptionServiceStatus.ACTIVE;
        this.graceEndsAt = null;
        if (wasGracePeriod) {
            registerEvent(new ServiceHeartbeatRecoveredEvent(tenantId, serviceName));
        }
    }

    /**
     * Check heartbeat status. Allowed from ACTIVE.
     * If heartbeat is overdue (beyond heartbeatIntervalHrs), transitions to GRACE_PERIOD.
     */
    public void checkHeartbeat() {
        requireStatusFor("checkHeartbeat",
            SubscriptionServiceStatus.ACTIVE, SubscriptionServiceStatus.GRACE_PERIOD);
        if (status == SubscriptionServiceStatus.GRACE_PERIOD) {
            return; // already in grace period
        }
        if (lastHeartbeatAt == null) {
            return; // no heartbeat recorded yet, shouldn't happen but be safe
        }
        Instant deadline = lastHeartbeatAt.plusSeconds((long) heartbeatIntervalHrs * 3600);
        if (Instant.now().isAfter(deadline)) {
            this.status = SubscriptionServiceStatus.GRACE_PERIOD;
            this.graceEndsAt = Instant.now().plusSeconds((long) gracePeriodDays * 86400);
            registerEvent(new ServiceHeartbeatLostEvent(tenantId, serviceName));
        }
    }

    /**
     * Degrade the service (from GRACE_PERIOD).
     */
    public void degrade() {
        requireStatus(SubscriptionServiceStatus.GRACE_PERIOD, "degrade");
        this.status = SubscriptionServiceStatus.DEGRADED;
        registerEvent(new ServiceDegradedEvent(tenantId, serviceName));
    }

    /**
     * Revoke the service. Allowed from PROVISIONED, ACTIVE, or GRACE_PERIOD.
     */
    public void revoke() {
        requireStatusFor("revoke",
            SubscriptionServiceStatus.PROVISIONED,
            SubscriptionServiceStatus.ACTIVE,
            SubscriptionServiceStatus.GRACE_PERIOD);
        this.status = SubscriptionServiceStatus.EXPIRED;
        registerEvent(new ServiceRevokedEvent(tenantId, serviceName));
    }

    /**
     * Expire the service (e.g. License file expired). Allowed from ACTIVE.
     */
    public void expire() {
        requireStatus(SubscriptionServiceStatus.ACTIVE, "expire");
        this.status = SubscriptionServiceStatus.EXPIRED;
        registerEvent(new ServiceRevokedEvent(tenantId, serviceName));
    }

    /**
     * Adjust device quota. Allowed from ACTIVE or GRACE_PERIOD.
     */
    public void adjustQuota(int newQuota) {
        requireStatusFor("adjustQuota",
            SubscriptionServiceStatus.ACTIVE, SubscriptionServiceStatus.GRACE_PERIOD);
        this.deviceQuota = newQuota;
        registerEvent(new ServiceQuotaAdjustedEvent(tenantId, serviceName, newQuota));
    }

    // ── Key verification ─────────────────────────────────────────────

    /**
     * Verify a service key using constant-time comparison to prevent timing attacks.
     *
     * @param rawKey the raw key to verify
     * @throws DomainException if the key does not match
     */
    public void verifyKey(String rawKey) {
        if (rawKey == null || rawKey.isEmpty()) {
            throw new DomainException(ErrorCode.SERVICE_KEY_MISMATCH,
                "Service key is required");
        }
        byte[] expectedHash = hexToBytes(this.serviceKeyHash);
        byte[] actualHash = sha256Bytes(rawKey);
        if (!MessageDigest.isEqual(expectedHash, actualHash)) {
            throw new DomainException(ErrorCode.SERVICE_KEY_MISMATCH,
                "Service key mismatch");
        }
    }

    // ── Guards ───────────────────────────────────────────────────────

    private void requireStatus(SubscriptionServiceStatus expected, String action) {
        if (this.status != expected) {
            throw new DomainException(ErrorCode.STATE_CONFLICT,
                "Cannot " + action + ": expected " + expected + " but was " + this.status);
        }
    }

    private void requireStatusFor(String action, SubscriptionServiceStatus... allowed) {
        for (SubscriptionServiceStatus s : allowed) {
            if (this.status == s) return;
        }
        throw new DomainException(ErrorCode.STATE_CONFLICT,
            "Cannot " + action + ": current status is " + this.status);
    }

    // ── Crypto helpers ───────────────────────────────────────────────

    private static String sha256Hex(String input) {
        byte[] hash = sha256Bytes(input);
        StringBuilder sb = new StringBuilder(hash.length * 2);
        for (byte b : hash) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    private static byte[] sha256Bytes(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return md.digest(input.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }

    private static byte[] hexToBytes(String hex) {
        int len = hex.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(hex.charAt(i), 16) << 4)
                + Character.digit(hex.charAt(i + 1), 16));
        }
        return data;
    }

    // ── Getters and Setters ──────────────────────────────────────────

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getServiceName() { return serviceName; }
    public void setServiceName(String serviceName) { this.serviceName = serviceName; }

    public String getServiceKeyPrefix() { return serviceKeyPrefix; }
    public void setServiceKeyPrefix(String serviceKeyPrefix) { this.serviceKeyPrefix = serviceKeyPrefix; }

    public String getServiceKeyHash() { return serviceKeyHash; }
    public void setServiceKeyHash(String serviceKeyHash) { this.serviceKeyHash = serviceKeyHash; }

    public SubscriptionTier getEffectiveTier() { return effectiveTier; }
    public void setEffectiveTier(SubscriptionTier effectiveTier) { this.effectiveTier = effectiveTier; }

    public Integer getDeviceQuota() { return deviceQuota; }
    public void setDeviceQuota(Integer deviceQuota) { this.deviceQuota = deviceQuota; }

    public SubscriptionServiceStatus getStatus() { return status; }
    public void setStatus(SubscriptionServiceStatus status) { this.status = status; }

    public Instant getLastHeartbeatAt() { return lastHeartbeatAt; }
    public void setLastHeartbeatAt(Instant lastHeartbeatAt) { this.lastHeartbeatAt = lastHeartbeatAt; }

    public Instant getGraceEndsAt() { return graceEndsAt; }
    public void setGraceEndsAt(Instant graceEndsAt) { this.graceEndsAt = graceEndsAt; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public int getHeartbeatIntervalHrs() { return heartbeatIntervalHrs; }
    public void setHeartbeatIntervalHrs(int heartbeatIntervalHrs) { this.heartbeatIntervalHrs = heartbeatIntervalHrs; }

    public int getGracePeriodDays() { return gracePeriodDays; }
    public void setGracePeriodDays(int gracePeriodDays) { this.gracePeriodDays = gracePeriodDays; }
}
