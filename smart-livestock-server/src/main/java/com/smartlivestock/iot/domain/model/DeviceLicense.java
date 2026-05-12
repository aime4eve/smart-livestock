package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * DeviceLicense aggregate root representing a device license / subscription.
 * <p>
 * A license is valid when status is ACTIVE and not yet expired.
 * It can be revoked (status → REVOKED), which is terminal.
 */
public class DeviceLicense extends AggregateRoot {

    private Long deviceId;
    private Long tenantId;
    private String licenseKey;
    private LicenseStatus status;
    private Instant activatedAt;
    private Instant expiresAt;

    public DeviceLicense() {
        this.status = LicenseStatus.ACTIVE;
        this.activatedAt = Instant.now();
    }

    public DeviceLicense(Long deviceId, Long tenantId, String licenseKey, Instant expiresAt) {
        this.deviceId = deviceId;
        this.tenantId = tenantId;
        this.licenseKey = licenseKey;
        this.expiresAt = expiresAt;
        this.status = LicenseStatus.ACTIVE;
        this.activatedAt = Instant.now();
    }

    /**
     * Check if this license is expired based on time.
     *
     * @return true if current time is past the expiry time
     */
    public boolean isExpired() {
        return Instant.now().isAfter(expiresAt);
    }

    /**
     * Check if this license is valid (ACTIVE and not expired).
     *
     * @return true if license is usable
     */
    public boolean isValid() {
        return status == LicenseStatus.ACTIVE && !isExpired();
    }

    /**
     * Revoke this license. Only non-revoked licenses can be revoked.
     *
     * @throws ApiException (STATE_CONFLICT) if license is already revoked
     */
    public void revoke() {
        if (status == LicenseStatus.REVOKED) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "License is already REVOKED");
        }
        this.status = LicenseStatus.REVOKED;
    }

    // --- Getters and Setters ---

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getLicenseKey() { return licenseKey; }
    public void setLicenseKey(String licenseKey) { this.licenseKey = licenseKey; }

    public LicenseStatus getStatus() { return status; }
    public void setStatus(LicenseStatus status) { this.status = status; }

    public Instant getActivatedAt() { return activatedAt; }

    /**
     * Reconstitute activatedAt from persistence.
     */
    public void reconstituteActivatedAt(Instant activatedAt) { this.activatedAt = activatedAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
}
