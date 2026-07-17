package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * GPS quality test: a truth-reference analysis within a session.
 * <p>
 * A test selects a sub-range of the parent session's time window and
 * specifies a truth reference:
 * <ul>
 *   <li>{@link TestType#STATIC} — truth is a single RTK point ({@code rtkPointId})</li>
 *   <li>{@link TestType#DYNAMIC} — truth is an ordered route ({@code routeId})</li>
 * </ul>
 * {@code rtkPointId} and {@code routeId} are mutually exclusive (DB CHECK constraint).
 * <p>
 * A test has no lifecycle — it is an analysis record created on demand.
 */
public class GpsQualityTest extends AggregateRoot {

    private Long sessionId;
    private TestType testType;
    private Long rtkPointId;
    private Long routeId;
    private Instant testStartedAt;
    private Instant testEndedAt;
    private Instant createdAt;
    private Instant updatedAt;

    public GpsQualityTest() {
        this.testType = TestType.STATIC;
    }

    /** Static-test convenience constructor. */
    public GpsQualityTest(Long sessionId, Long rtkPointId, Instant testStartedAt) {
        this(sessionId, TestType.STATIC, rtkPointId, null, testStartedAt);
    }

    /**
     * Full constructor.
     *
     * @param sessionId      parent session
     * @param testType       STATIC or DYNAMIC
     * @param rtkPointId     STATIC truth point (null when DYNAMIC)
     * @param routeId        DYNAMIC truth route (null when STATIC)
     * @param testStartedAt  sub-range start within session
     */
    public GpsQualityTest(Long sessionId, TestType testType, Long rtkPointId, Long routeId, Instant testStartedAt) {
        this.sessionId = sessionId;
        this.testType = testType != null ? testType : TestType.STATIC;
        this.rtkPointId = rtkPointId;
        this.routeId = routeId;
        this.testStartedAt = testStartedAt;
    }

    // --- Getters and Setters ---

    public Long getSessionId() { return sessionId; }
    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }

    public TestType getTestType() { return testType; }
    public void setTestType(TestType testType) { this.testType = testType; }

    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }

    public Long getRouteId() { return routeId; }
    public void setRouteId(Long routeId) { this.routeId = routeId; }

    public Instant getTestStartedAt() { return testStartedAt; }
    public void setTestStartedAt(Instant testStartedAt) { this.testStartedAt = testStartedAt; }

    public Instant getTestEndedAt() { return testEndedAt; }
    public void setTestEndedAt(Instant testEndedAt) { this.testEndedAt = testEndedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
