package com.smartlivestock.health.infrastructure.acl;

import com.smartlivestock.health.domain.port.GpsTrajectoryPort;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;

/**
 * ACL adapter resolving a livestock trajectory through the IoT context:
 * livestock -> active installation (tracker first, ear tag fallback — same
 * preference as InstallationApplicationService#getActiveInstallationByLivestock)
 * -> device -> gps_logs window query.
 */
@Component("healthGpsTrajectoryPort")
public class GpsTrajectoryPortImpl implements GpsTrajectoryPort {

    private final InstallationRepository installationRepository;
    private final GpsLogRepository gpsLogRepository;

    public GpsTrajectoryPortImpl(InstallationRepository installationRepository,
                                 GpsLogRepository gpsLogRepository) {
        this.installationRepository = installationRepository;
        this.gpsLogRepository = gpsLogRepository;
    }

    @Override
    public List<GpsPoint> findTrajectory(Long livestockId, Instant from, Instant to) {
        return installationRepository
                .findActiveByLivestockIdAndDeviceType(livestockId, DeviceType.TRACKER)
                .or(() -> installationRepository.findActiveByLivestockIdAndDeviceType(
                        livestockId, DeviceType.EAR_TAG))
                .map(inst -> gpsLogRepository.findByDeviceIdAndRecordedAtBetween(
                        inst.getDeviceId(), from, to))
                .orElseGet(List::of)
                .stream()
                .filter(p -> p.getRecordedAt() != null
                        && p.getLatitude() != null && p.getLongitude() != null)
                .map(p -> new GpsPoint(p.getRecordedAt(),
                        p.getLatitude().doubleValue(), p.getLongitude().doubleValue()))
                .toList();
    }
}
