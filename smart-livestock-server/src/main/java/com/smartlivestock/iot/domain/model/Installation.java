package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.Entity;

import java.time.Instant;

/**
 * Installation entity representing the binding of a device to a livestock animal.
 * <p>
 * An installation is active when removedAt is null.
 * Once removed, it cannot be removed again.
 */
public class Installation extends Entity {

    private Long deviceId;
    private Long livestockId;
    private Instant installedAt;
    private Instant removedAt;
    private Long operatorId;

    public Installation() {
        this.installedAt = Instant.now();
    }

    public Installation(Long deviceId, Long livestockId, Long operatorId) {
        this.deviceId = deviceId;
        this.livestockId = livestockId;
        this.operatorId = operatorId;
        this.installedAt = Instant.now();
    }

    /**
     * Check if this installation is currently active.
     *
     * @return true if the device is still installed on the livestock
     */
    public boolean isActive() {
        return removedAt == null;
    }

    /**
     * Remove this installation (uninstall device from livestock).
     *
     * @throws ApiException (STATE_CONFLICT) if installation is already removed
     */
    public void remove() {
        if (removedAt != null) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Installation is already removed");
        }
        this.removedAt = Instant.now();
    }

    // --- Getters and Setters ---

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }

    public Instant getInstalledAt() { return installedAt; }

    public Instant getRemovedAt() { return removedAt; }

    /**
     * Reconstitute installedAt from persistence.
     */
    public void reconstituteInstalledAt(Instant installedAt) { this.installedAt = installedAt; }

    /**
     * Reconstitute removedAt from persistence.
     */
    public void reconstituteRemovedAt(Instant removedAt) { this.removedAt = removedAt; }

    public Long getOperatorId() { return operatorId; }
    public void setOperatorId(Long operatorId) { this.operatorId = operatorId; }
}
