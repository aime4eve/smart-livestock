package com.smartlivestock.ranch.domain.port;

import com.smartlivestock.ranch.domain.port.dto.DeviceBrief;
import com.smartlivestock.ranch.domain.port.dto.DeviceStatsInfo;
import com.smartlivestock.ranch.domain.port.dto.InstallationInfo;
import com.smartlivestock.ranch.domain.port.dto.TrackDraftPoint;
import com.smartlivestock.ranch.domain.port.dto.TrackerCandidate;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public interface IoTQueryPort {
    Optional<InstallationInfo> findActiveInstallation(Long deviceId);
    DeviceStatsInfo getDeviceStats(Long tenantId);

    boolean hasActiveInstallationByLivestock(Long livestockId);

    /**
     * ACTIVE devices / total devices for the tenant. {@code null} when the
     * tenant owns no devices — an empty fleet is "unknown", never "100%".
     */
    Double getDeviceOnlineRate(Long tenantId);

    /**
     * Batch query active devices for multiple livestock.
     * @param livestockIds livestock IDs to query (empty list returns empty map)
     * @return Map: livestockId -> List<DeviceBrief>;
     *         livestock without devices will not appear as a key
     */
    Map<Long, List<DeviceBrief>> findActiveDevicesByLivestockIds(List<Long> livestockIds);

    /**
     * Batch resolve device serial codes for device-originated alerts.
     * @param deviceIds device IDs to query (empty list returns empty map)
     * @return Map: deviceId -> deviceCode; unknown ids will not appear as a key
     */
    Map<Long, String> findDeviceCodesByIds(List<Long> deviceIds);

    /**
     * Raw gps_logs row count for one device in [from, to] — the cheap
     * pre-count behind the fence track-draft stride estimate.
     */
    long countTrackPoints(Long deviceId, Instant from, Instant to);

    /**
     * Stride sampling over gps_logs (ROW_NUMBER ascending, keep 1 of every
     * {@code stride}) for the fence track-draft preview.
     */
    List<TrackDraftPoint> sampleTrackPoints(Long deviceId, Instant from, Instant to, long stride);

    /**
     * TRACKER devices with an active installation on the farm's livestock,
     * each with its point count and latest fix inside the last {@code days}
     * days. Sorted by lastFixAt descending (nulls last).
     */
    List<TrackerCandidate> findTrackerCandidates(Long farmId, int days);
}
