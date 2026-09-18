package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.model.GatewayDistanceStats;
import com.smartlivestock.iot.domain.model.GatewayLatestFix;
import com.smartlivestock.iot.domain.model.GatewayRegistry;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.GatewayRegistryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Frame-level communication distance between a device and each gateway
 * (NIX-219 F2). Distance is computed against the gateway that actually
 * received the frame — never a single aggregated number. Governance-flagged
 * coordinates never enter: the underlying queries pre-filter them.
 */
@Service
@RequiredArgsConstructor
public class GatewayDistanceService {

    private static final Duration STATS_WINDOW = Duration.ofDays(30);
    private static final Duration FIX_WINDOW = Duration.ofDays(90);

    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final GatewayRegistryRepository gatewayRegistryRepository;
    private final com.smartlivestock.iot.application.GatewayDistanceProfileService profileService;

    public record GatewayDistanceView(
            String gatewayId,
            Instant lastSeen,
            long frames,
            Double latestMeters,
            Double medianMeters,
            Double p95Meters) {
    }

    public record NearestGateway(String gatewayId, double meters, Instant asOf) {
    }

    /** Plan-B inferred distance for gateways whose frames carry no valid GPS. */
    public record InferredDistance(
            String gatewayId,
            Instant lastSeen,
            int rssi,
            Double p50Meters,
            Double p90Meters,
            String source) {
    }

    public record DeviceGatewayDistanceView(
            List<GatewayDistanceView> byGateway,
            List<InferredDistance> inferred,
            NearestGateway nearest) {
    }

    public DeviceGatewayDistanceView deviceDistances(Long deviceId) {
        Instant statsSince = Instant.now().minus(STATS_WINDOW);
        List<GatewayDistanceStats> stats =
                deviceTelemetryLogRepository.aggregateGatewayDistances(deviceId, statsSince);

        Map<String, GatewayLatestFix> latestFixByGateway = new HashMap<>();
        deviceTelemetryLogRepository
                .findLatestFixesByGateway(deviceId, Instant.now().minus(FIX_WINDOW))
                .forEach(fix -> latestFixByGateway.put(fix.gatewayId(), fix));

        List<GatewayDistanceView> views = new ArrayList<>();
        for (GatewayDistanceStats stat : stats) {
            GatewayLatestFix fix = latestFixByGateway.get(stat.gatewayId());
            Double latestMeters = null;
            if (fix != null) {
                GatewayRegistry registry =
                        gatewayRegistryRepository.findByGatewayId(stat.gatewayId()).orElse(null);
                if (registry != null) {
                    latestMeters = TrackLineCalculator.haversineMeters(
                            fix.latitude().doubleValue(), fix.longitude().doubleValue(),
                            registry.getLatitude().doubleValue(),
                            registry.getLongitude().doubleValue());
                }
            }
            views.add(new GatewayDistanceView(
                    stat.gatewayId(), stat.lastSeen(), stat.frames(),
                    latestMeters, stat.medianMeters(), stat.p95Meters()));
        }
        views.sort((a, b) -> {
            Instant la = a.lastSeen(), lb = b.lastSeen();
            if (la == null || lb == null) return la == null ? 1 : -1;
            return lb.compareTo(la);
        });

        // Plan-B inference for gateways whose frames have no valid GPS fix.
        List<InferredDistance> inferred = new ArrayList<>();
        deviceTelemetryLogRepository
                .findLatestRssiByGateway(deviceId, Instant.now().minus(FIX_WINDOW))
                .forEach(latest -> {
                    boolean hasGpsStats = stats.stream()
                            .anyMatch(s -> s.gatewayId().equals(latest.gatewayId()));
                    if (hasGpsStats) {
                        return;
                    }
                    var result = profileService.infer(latest.gatewayId(), latest.rssi());
                    if (result != null) {
                        inferred.add(new InferredDistance(
                                latest.gatewayId(), latest.reportTime(), latest.rssi(),
                                result.p50Meters(), result.p90Meters(), result.source()));
                    }
                });

        return new DeviceGatewayDistanceView(views, inferred, nearestGateway(latestFixByGateway));
    }

    /**
     * Derived view: distance from the device's overall latest valid fix to every
     * registered gateway, minimum wins ("which coverage area is it in now").
     */
    private NearestGateway nearestGateway(Map<String, GatewayLatestFix> latestFixByGateway) {
        GatewayLatestFix deviceFix = latestFixByGateway.values().stream()
                .filter(f -> f.latitude() != null && f.longitude() != null)
                .min((a, b) -> b.reportTime().compareTo(a.reportTime()))
                .orElse(null);
        if (deviceFix == null) {
            return null;
        }
        NearestGateway best = null;
        for (GatewayRegistry registry : gatewayRegistryRepository.findAll()) {
            double meters = TrackLineCalculator.haversineMeters(
                    deviceFix.latitude().doubleValue(), deviceFix.longitude().doubleValue(),
                    registry.getLatitude().doubleValue(),
                    registry.getLongitude().doubleValue());
            if (best == null || meters < best.meters()) {
                best = new NearestGateway(registry.getGatewayId(), meters, deviceFix.reportTime());
            }
        }
        return best;
    }
}
