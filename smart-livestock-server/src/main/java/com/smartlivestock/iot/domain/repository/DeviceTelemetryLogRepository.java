package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface DeviceTelemetryLogRepository {
    DeviceTelemetryLog save(DeviceTelemetryLog log);

    /** Find the most recent telemetry log for a device (used for stepNumber delta calculation). */
    Optional<DeviceTelemetryLog> findLatestByDeviceId(Long deviceId);

    /** Find the latest cumulative counter value reported before a report time. */
    Optional<DeviceTelemetryLog> findLatestStepNumberByDeviceIdAndReportTimeBefore(
            Long deviceId, Instant reportTime);

    /** Find the latest cumulative gastric motility counter before a report time. */
    Optional<DeviceTelemetryLog> findLatestGastricMotilityByDeviceIdAndReportTimeBefore(
            Long deviceId, Instant reportTime);

    /** Find the closest valid GPS fix before a report time. */
    Optional<DeviceTelemetryLog> findLatestGpsByDeviceIdAndReportTimeBefore(
            Long deviceId, Instant reportTime);

    /** Whether a telemetry frame has already been persisted for this device/time. */
    boolean existsByDeviceIdAndReportTime(Long deviceId, Instant reportTime);

    /** Report times of a device's telemetry rows within [min, max] (import duplicate pre-check, NIX-79). */
    List<Instant> findReportTimesByDeviceIdAndReportTimeBetween(Long deviceId, Instant min, Instant max);

    // --- Gateway distance features (NIX-219) ---

    /**
     * Gateway usage aggregation for gateway discovery: which gateways the given
     * devices talked to since the given time, with last-seen time and frame count.
     */
    List<com.smartlivestock.iot.domain.model.GatewayUsageSummary> aggregateGatewayUsage(
            List<Long> deviceIds, Instant since);

    /** Distinct non-blank gateway ids seen since the given time (admin reconciliation, F10). */
    List<String> findDistinctGatewayIds(Instant since);

    /**
     * Per-gateway frame-level distance statistics for one device over the window:
     * Haversine between the frame GPS fix and the receiving gateway's registered
     * position. Only valid coordinates and registered gateways are counted.
     */
    List<com.smartlivestock.iot.domain.model.GatewayDistanceStats> aggregateGatewayDistances(
            Long deviceId, Instant since);

    /** Latest valid GPS fix per gateway for one device (any gateway, registered or not). */
    List<com.smartlivestock.iot.domain.model.GatewayLatestFix> findLatestFixesByGateway(Long deviceId, Instant since);

    /**
     * Averages over the most recent frames of one device through one gateway
     * (NIX-219 F3 link quality). Empty when no qualifying frame exists.
     */
    Optional<com.smartlivestock.iot.domain.model.LinkQualityStats> recentLinkQuality(
            Long deviceId, String gatewayId, Instant since, int limitFrames);

    /**
     * Calibration samples for the dynamic RSSI→distance map of one gateway
     * (NIX-219 plan B): GPS-valid frames with non-null RSSI whose gateway is
     * registered; distance in metres to the registered gateway position.
     */
    List<com.smartlivestock.iot.domain.model.RssiDistanceSample> rssiDistanceSamples(
            String gatewayId, Instant since);

    /** Latest frame with RSSI per gateway for one device, GPS validity not required. */
    List<com.smartlivestock.iot.domain.model.GatewayLatestRssi> findLatestRssiByGateway(
            Long deviceId, Instant since);

    /**
     * Frame-level distances (metres) to the receiving registered gateway for one
     * device within [from, to) — F6 roaming-radius aggregation input.
     */
    List<Double> roamDistanceSamples(Long deviceId, Instant from, Instant to);

    // --- F8 coverage diagnostics ---

    /** 100m-grid aggregation of valid frames (count / avg RSSI / centroid) per cell. */
    List<com.smartlivestock.iot.domain.model.CoverageCellRow> coverageCellRows(
            List<Long> deviceIds, Instant since, int minCellFrames);

    /** Global tier totals + all-frame centroid over the window. */
    com.smartlivestock.iot.domain.model.CoverageTierTotals coverageTierTotals(
            List<Long> deviceIds, Instant since);

    /** Centroid of weak frames (RSSI < -95) — direction test for relocation advice. */
    com.smartlivestock.iot.domain.model.WeakCentroidRow weakCentroid(
            List<Long> deviceIds, Instant since);
}
