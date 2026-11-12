package com.smartlivestock.ranch.infrastructure.acl;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.dto.DeviceBrief;
import com.smartlivestock.ranch.domain.port.dto.DeviceStatsInfo;
import com.smartlivestock.ranch.domain.port.dto.InstallationInfo;
import com.smartlivestock.ranch.domain.port.dto.TrackDraftPoint;
import com.smartlivestock.ranch.domain.port.dto.TrackerCandidate;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Component("ranchIoTQueryPort")
public class IoTQueryPortImpl implements IoTQueryPort {

    private final DeviceRepository deviceRepository;
    private final InstallationRepository installationRepository;
    private final DeviceApplicationService deviceApplicationService;
    private final GpsLogRepository gpsLogRepository;
    private final LivestockRepository livestockRepository;

    public IoTQueryPortImpl(DeviceRepository deviceRepository,
                             InstallationRepository installationRepository,
                             DeviceApplicationService deviceApplicationService,
                             GpsLogRepository gpsLogRepository,
                             LivestockRepository livestockRepository) {
        this.deviceRepository = deviceRepository;
        this.installationRepository = installationRepository;
        this.deviceApplicationService = deviceApplicationService;
        this.gpsLogRepository = gpsLogRepository;
        this.livestockRepository = livestockRepository;
    }

    @Override
    public Optional<InstallationInfo> findActiveInstallation(Long deviceId) {
        return installationRepository.findActiveByDeviceId(deviceId)
                .map(i -> new InstallationInfo(i.getId(), i.getDeviceId(), i.getLivestockId()));
    }

    @Override
    public DeviceStatsInfo getDeviceStats(Long tenantId) {
        long active = deviceApplicationService.countActiveByTenant();
        return new DeviceStatsInfo(active);
    }

    // Count-based: avoids loading the entire tenant device list into memory.
    @Override
    public Double getDeviceOnlineRate(Long tenantId) {
        long active = deviceRepository.countByTenantIdAndStatus(tenantId, DeviceStatus.ACTIVE.name());
        long total = deviceRepository.countByTenantIdPaged(tenantId);
        // 空租户 = 未知而非 100%（旧实现空牧场假显 100%，2026-10-19 语义修正）
        if (total == 0) return null;
        return (double) active / total;
    }

    @Override
    public boolean hasActiveInstallationByLivestock(Long livestockId) {
        return installationRepository.findByLivestockId(livestockId).stream()
                .anyMatch(i -> i.getRemovedAt() == null);
    }

    @Override
    public Map<Long, List<DeviceBrief>> findActiveDevicesByLivestockIds(List<Long> livestockIds) {
        if (livestockIds == null || livestockIds.isEmpty()) {
            return Collections.emptyMap();
        }
        // Batch query active installations for all livestock
        List<Installation> installations = installationRepository.findByLivestockIdIn(livestockIds);
        // Filter to active only
        List<Installation> active = installations.stream()
                .filter(i -> i.getRemovedAt() == null)
                .toList();
        if (active.isEmpty()) {
            return Collections.emptyMap();
        }
        // Batch query devices
        List<Long> deviceIds = active.stream().map(Installation::getDeviceId).distinct().toList();
        Map<Long, Device> deviceMap = deviceIds.stream()
                .map(deviceRepository::findById)
                .filter(Optional::isPresent)
                .map(Optional::get)
                .collect(Collectors.toMap(Device::getId, d -> d));
        // Group by livestockId
        return active.stream()
                .filter(i -> deviceMap.containsKey(i.getDeviceId()))
                .collect(Collectors.groupingBy(
                        Installation::getLivestockId,
                        Collectors.mapping(
                                i -> toDeviceBrief(deviceMap.get(i.getDeviceId())),
                                Collectors.toList()
                        )
                ));
    }

    @Override
    public Map<Long, String> findDeviceCodesByIds(List<Long> deviceIds) {
        if (deviceIds == null || deviceIds.isEmpty()) {
            return Collections.emptyMap();
        }
        return deviceRepository.findAllByIdIn(deviceIds).stream()
                .filter(d -> d.getDeviceCode() != null)
                .collect(Collectors.toMap(Device::getId, Device::getDeviceCode, (a, b) -> a));
    }

    @Override
    public long countTrackPoints(Long deviceId, Instant from, Instant to) {
        return gpsLogRepository.countByDeviceIdAndRecordedAtBetween(deviceId, from, to);
    }

    @Override
    public List<TrackDraftPoint> sampleTrackPoints(Long deviceId, Instant from, Instant to, long stride) {
        return gpsLogRepository.sampleByDeviceIdAndTimeRange(deviceId, from, to, stride).stream()
                .map(IoTQueryPortImpl::toTrackDraftPoint)
                .toList();
    }

    @Override
    public List<TrackerCandidate> findTrackerCandidates(Long farmId, int days) {
        List<Livestock> farmLivestock = livestockRepository.findByFarmId(farmId);
        if (farmLivestock.isEmpty()) {
            return List.of();
        }
        Map<Long, Livestock> livestockById = farmLivestock.stream()
                .collect(Collectors.toMap(Livestock::getId, l -> l));
        List<Installation> active = installationRepository
                .findByLivestockIdIn(new ArrayList<>(livestockById.keySet())).stream()
                .filter(i -> i.getRemovedAt() == null)
                .toList();
        if (active.isEmpty()) {
            return List.of();
        }
        List<Long> deviceIds = active.stream().map(Installation::getDeviceId).distinct().toList();
        Map<Long, Device> trackers = deviceRepository.findAllByIdIn(deviceIds).stream()
                .filter(d -> d.getDeviceType() == DeviceType.TRACKER)
                .collect(Collectors.toMap(Device::getId, d -> d));

        Instant now = Instant.now();
        Instant windowFrom = now.minus(days, ChronoUnit.DAYS);
        List<TrackerCandidate> candidates = new ArrayList<>();
        for (Installation installation : active) {
            Device device = trackers.get(installation.getDeviceId());
            if (device == null) {
                continue;
            }
            Livestock livestock = livestockById.get(installation.getLivestockId());
            long pointCount = gpsLogRepository.countByDeviceIdAndRecordedAtBetween(
                    device.getId(), windowFrom, now);
            Instant lastFixAt = gpsLogRepository
                    .findLastRecordedAtAtOrAfter(device.getId(), windowFrom)
                    .orElse(null);
            candidates.add(new TrackerCandidate(
                    device.getId(),
                    device.getDeviceCode(),
                    livestock != null ? livestock.getLivestockCode() : null,
                    lastFixAt,
                    pointCount));
        }
        candidates.sort(Comparator.comparing(
                TrackerCandidate::lastFixAt,
                Comparator.nullsLast(Comparator.reverseOrder())));
        return candidates;
    }

    private static TrackDraftPoint toTrackDraftPoint(GpsLog log) {
        return new TrackDraftPoint(
                log.getLatitude(),
                log.getLongitude(),
                log.getAccuracy() != null ? log.getAccuracy().doubleValue() : null,
                log.getRecordedAt());
    }

    private DeviceBrief toDeviceBrief(Device device) {
        return new DeviceBrief(
                device.getId(),
                device.getDeviceCode(),
                device.getDevEui(),
                device.getDeviceType() != null ? device.getDeviceType().name() : null
        );
    }
}
