package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * GPS quality test: a truth-reference analysis directly on a device's data.
 * <p>
 * A test selects a time range within a device's GPS data and specifies a
 * truth reference:
 * <ul>
 *   <li>{@link TestType#STATIC} — truth is a single RTK point ({@code rtkPointId})</li>
 *   <li>{@link TestType#DYNAMIC} — truth is an ordered route ({@code routeId})</li>
 *   <li>{@link TestType#TRAJECTORY} — truth is an imported RTK track (pairing snapshot)</li>
 *   <li>{@link TestType#LINE} — truth is a standard track line ({@code trackLineId})</li>
 * </ul>
 * Exactly one truth reference is set per test (DB CHECK constraint).
 * <p>
 * A test has no lifecycle — it is an analysis record created on demand.
 * <p>
 * Status values: READY (created, pending processing), DEVICE_PENDING (device not
 * yet registered on blade platform), FAILED (platform registration or data fetch failed).
 */
public class GpsQualityTest extends AggregateRoot {

    private String deviceCode;
    private Long deviceId;
    private TestType testType;
    private Long rtkPointId;
    private Long routeId;
    private Long trackLineId;
    private Instant startedAt;
    private Instant endedAt;
    private String status;
    private String errorMessage;
    private String note;
    private Long batchImportId;
    private Instant createdAt;
    private Instant updatedAt;

    public GpsQualityTest() {
        this.testType = TestType.STATIC;
        this.status = "READY";
    }

    /** Static-test convenience constructor. */
    public GpsQualityTest(String deviceCode, Long rtkPointId, Instant startedAt) {
        this.deviceCode = deviceCode;
        this.testType = TestType.STATIC;
        this.rtkPointId = rtkPointId;
        this.startedAt = startedAt;
        this.status = "READY";
    }

    /**
     * Full constructor (STATIC / DYNAMIC / TRAJECTORY).
     *
     * @param deviceCode  device identifier
     * @param testType    STATIC, DYNAMIC or TRAJECTORY
     * @param rtkPointId  STATIC truth point (null when DYNAMIC/TRAJECTORY)
     * @param routeId     DYNAMIC truth route (null when STATIC/TRAJECTORY)
     * @param startedAt   analysis window start
     */
    public GpsQualityTest(String deviceCode, TestType testType, Long rtkPointId, Long routeId, Instant startedAt) {
        this.deviceCode = deviceCode;
        this.testType = testType != null ? testType : TestType.STATIC;
        this.rtkPointId = rtkPointId;
        this.routeId = routeId;
        this.startedAt = startedAt;
        this.status = "READY";
    }

    /**
     * Full constructor including the LINE truth reference.
     *
     * @param deviceCode  device identifier
     * @param testType    STATIC, DYNAMIC, TRAJECTORY or LINE
     * @param rtkPointId  STATIC truth point (null otherwise)
     * @param routeId     DYNAMIC truth route (null otherwise)
     * @param trackLineId LINE standard track line (null otherwise)
     * @param startedAt   analysis window start
     */
    public GpsQualityTest(String deviceCode, TestType testType, Long rtkPointId, Long routeId,
                          Long trackLineId, Instant startedAt) {
        this.deviceCode = deviceCode;
        this.testType = testType != null ? testType : TestType.STATIC;
        this.rtkPointId = rtkPointId;
        this.routeId = routeId;
        this.trackLineId = trackLineId;
        this.startedAt = startedAt;
        this.status = "READY";
    }

    // --- Getters and Setters ---

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public TestType getTestType() { return testType; }
    public void setTestType(TestType testType) { this.testType = testType; }

    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }

    public Long getRouteId() { return routeId; }
    public void setRouteId(Long routeId) { this.routeId = routeId; }

    public Long getTrackLineId() { return trackLineId; }
    public void setTrackLineId(Long trackLineId) { this.trackLineId = trackLineId; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public Long getBatchImportId() { return batchImportId; }
    public void setBatchImportId(Long batchImportId) { this.batchImportId = batchImportId; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
