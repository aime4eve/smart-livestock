package com.smartlivestock.shared.messaging;

/**
 * Central registry of all RocketMQ topic names used for cross-context event distribution.
 * <p>
 * Each bounded context publishes domain events to these topics so other contexts
 * can react without direct code-level coupling.
 */
public final class Topics {

    private Topics() {
        // prevent instantiation
    }

    /** IoT context publishes when a new GPS log is recorded for a device. */
    public static final String GPS_LOG_UPDATED = "gps-log-updated";

    /** IoT context publishes when a device transitions to ACTIVATED status. */
    public static final String DEVICE_ACTIVATED = "device-activated";

    /** IoT context publishes when a device license expires. */
    public static final String LICENSE_EXPIRED = "license-expired";

    /** Ranch context publishes when a livestock is detected outside a fence boundary. */
    public static final String FENCE_BREACH_DETECTED = "fence-breach-detected";

    /** Ranch context publishes when an alert transitions to a new status. */
    public static final String ALERT_STATUS_CHANGED = "alert-status-changed";

    /** Identity context publishes when a tenant's phase changes. */
    public static final String TENANT_PHASE_CHANGED = "tenant-phase-changed";
}
