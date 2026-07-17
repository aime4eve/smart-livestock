package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * GPS quality session: a device's data collection window.
 * <p>
 * A session defines a time range during which a device collected GPS data.
 * Multiple tests (static or dynamic) can be created within a session,
 * each analyzing a sub-range of the session's data with different truth references.
 * <p>
 * Lifecycle: IN_PROGRESS -> COMPLETED | CANCELED
 */
public class GpsQualitySession extends AggregateRoot {

    private Long deviceId;
    private Instant startedAt;
    private Instant endedAt;
    private SessionStatus status;
    private String note;
    private Instant createdAt;
    private Instant updatedAt;

    public GpsQualitySession() {
        this.status = SessionStatus.IN_PROGRESS;
    }

    public GpsQualitySession(Long deviceId, Instant startedAt) {
        this.deviceId = deviceId;
        this.startedAt = startedAt;
        this.status = SessionStatus.IN_PROGRESS;
    }

    public void end() {
        if (status != SessionStatus.IN_PROGRESS) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Session must be IN_PROGRESS to end, current: " + status);
        }
        this.status = SessionStatus.COMPLETED;
        this.endedAt = Instant.now();
    }

    public void cancel() {
        if (status == SessionStatus.CANCELED) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Session is already CANCELED");
        }
        this.status = SessionStatus.CANCELED;
    }

    // --- Getters and Setters ---

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }

    public SessionStatus getStatus() { return status; }
    public void setStatus(SessionStatus status) { this.status = status; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
