package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * GPS quality test aggregate root (unified STATIC + DYNAMIC).
 * <p>
 * A test links a device to a truth reference for a time window:
 * <ul>
 *   <li>{@link TestType#STATIC} — truth is a single RTK point ({@code rtkPointId})</li>
 *   <li>{@link TestType#DYNAMIC} — truth is an ordered route ({@code routeId})</li>
 * </ul>
 * {@code rtkPointId} and {@code routeId} are mutually exclusive (DB CHECK constraint).
 * <p>
 * Lifecycle status machine: IN_PROGRESS → COMPLETED | CANCELED
 * <ul>
 *   <li>{@code end()} — only IN_PROGRESS can transition to COMPLETED</li>
 *   <li>{@code cancel()} — any non-CANCELED status can transition to CANCELED</li>
 * </ul>
 */
public class GpsQualityTest extends AggregateRoot {

    private TestType testType;
    private Long rtkPointId;
    private Long routeId;
    private Long deviceId;
    private Instant startedAt;
    private Instant endedAt;
    private CalibrationStatus status;
    private Instant createdAt;
    private Instant updatedAt;

    public GpsQualityTest() {
        this.testType = TestType.STATIC;
        this.status = CalibrationStatus.IN_PROGRESS;
    }

    /** Static-test convenience constructor (defaults test_type to STATIC). */
    public GpsQualityTest(Long rtkPointId, Long deviceId, Instant startedAt) {
        this(TestType.STATIC, rtkPointId, null, deviceId, startedAt);
    }

    /**
     * Full constructor: test_type plus its mutually exclusive truth reference.
     *
     * @param testType   STATIC or DYNAMIC (null defaults to STATIC)
     * @param rtkPointId STATIC truth point (null when DYNAMIC)
     * @param routeId    DYNAMIC truth route (null when STATIC)
     */
    public GpsQualityTest(TestType testType, Long rtkPointId, Long routeId, Long deviceId, Instant startedAt) {
        this.testType = testType != null ? testType : TestType.STATIC;
        this.rtkPointId = rtkPointId;
        this.routeId = routeId;
        this.deviceId = deviceId;
        this.startedAt = startedAt;
        this.status = CalibrationStatus.IN_PROGRESS;
    }

    /**
     * End this test. Only IN_PROGRESS tests can be ended.
     *
     * @throws ApiException (STATE_CONFLICT) if test is not in IN_PROGRESS status
     */
    public void end() {
        if (status != CalibrationStatus.IN_PROGRESS) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "GPS quality test must be IN_PROGRESS to end, current: " + status);
        }
        this.status = CalibrationStatus.COMPLETED;
        this.endedAt = Instant.now();
    }

    /**
     * Cancel this test. Any non-CANCELED test can be canceled.
     *
     * @throws ApiException (STATE_CONFLICT) if test is already CANCELED
     */
    public void cancel() {
        if (status == CalibrationStatus.CANCELED) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "GPS quality test is already CANCELED");
        }
        this.status = CalibrationStatus.CANCELED;
    }

    // --- Getters and Setters ---

    public TestType getTestType() { return testType; }
    public void setTestType(TestType testType) { this.testType = testType; }

    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }

    public Long getRouteId() { return routeId; }
    public void setRouteId(Long routeId) { this.routeId = routeId; }

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
