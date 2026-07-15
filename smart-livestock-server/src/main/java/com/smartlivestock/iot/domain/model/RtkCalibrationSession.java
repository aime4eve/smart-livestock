package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * RTK calibration session aggregate root.
 * <p>
 * Links a device to an RTK reference point for a static-test window.
 * Lifecycle status machine: IN_PROGRESS → COMPLETED | CANCELED
 * <ul>
 *   <li>{@code end()} — only IN_PROGRESS can transition to COMPLETED</li>
 *   <li>{@code cancel()} — any non-CANCELED status can transition to CANCELED</li>
 * </ul>
 */
public class RtkCalibrationSession extends AggregateRoot {

    private Long rtkPointId;
    private Long deviceId;
    private Instant startedAt;
    private Instant endedAt;
    private CalibrationStatus status;
    private Instant createdAt;
    private Instant updatedAt;

    public RtkCalibrationSession() {
        this.status = CalibrationStatus.IN_PROGRESS;
    }

    public RtkCalibrationSession(Long rtkPointId, Long deviceId, Instant startedAt) {
        this.rtkPointId = rtkPointId;
        this.deviceId = deviceId;
        this.startedAt = startedAt;
        this.status = CalibrationStatus.IN_PROGRESS;
    }

    /**
     * End this calibration session. Only IN_PROGRESS sessions can be ended.
     *
     * @throws ApiException (STATE_CONFLICT) if session is not in IN_PROGRESS status
     */
    public void end() {
        if (status != CalibrationStatus.IN_PROGRESS) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Calibration session must be IN_PROGRESS to end, current: " + status);
        }
        this.status = CalibrationStatus.COMPLETED;
        this.endedAt = Instant.now();
    }

    /**
     * Cancel this calibration session. Any non-CANCELED session can be canceled.
     *
     * @throws ApiException (STATE_CONFLICT) if session is already CANCELED
     */
    public void cancel() {
        if (status == CalibrationStatus.CANCELED) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Calibration session is already CANCELED");
        }
        this.status = CalibrationStatus.CANCELED;
    }

    // --- Getters and Setters ---

    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }

    public CalibrationStatus getStatus() { return status; }
    public void setStatus(CalibrationStatus status) { this.status = status; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
