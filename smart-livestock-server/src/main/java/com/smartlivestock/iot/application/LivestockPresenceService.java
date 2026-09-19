package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.GatewayLatestFix;
import com.smartlivestock.iot.domain.model.GatewayRegistry;
import com.smartlivestock.iot.domain.model.LivestockRoamDaily;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.GatewayRegistryRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.iot.domain.repository.LivestockRoamRepository;
import com.smartlivestock.iot.domain.service.TrackLineCalculator;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Livestock presence scenarios on top of per-gateway distances (NIX-219):
 * F4 outlier/theft watch (farm baseline = median + MAD, no fence needed),
 * F5 return-home roll call at a configured evening hour, and F6 daily
 * roaming-radius aggregates for the health profile.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LivestockPresenceService {

    private static final Duration FIX_WINDOW = Duration.ofDays(90);

    private final InstallationRepository installationRepository;
    private final DeviceRepository deviceRepository;
    private final RanchQueryPort ranchQueryPort;
    private final GatewayRegistryRepository gatewayRegistryRepository;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final LivestockRoamRepository livestockRoamRepository;
    private final AlertRepository alertRepository;
    private final ObjectMapper objectMapper;

    @Value("${smartlivestock.presence.return-home.threshold-m:200}")
    private double returnHomeThresholdM;

    @Value("${smartlivestock.presence.outlier.mad-multiplier:3.0}")
    private double outlierMadMultiplier;

    @Value("${smartlivestock.presence.outlier.min-distance-m:1500}")
    private double outlierMinDistanceM;

    public double getReturnHomeThresholdM() { return returnHomeThresholdM; }
    public double getOutlierMadMultiplier() { return outlierMadMultiplier; }
    public double getOutlierMinDistanceM() { return outlierMinDistanceM; }

    /** Runtime threshold update (admin endpoint); resets to env defaults on restart. */
    public void updateThresholds(Double returnHomeThresholdM, Double outlierMadMultiplier,
                                 Double outlierMinDistanceM) {
        if (returnHomeThresholdM != null) this.returnHomeThresholdM = returnHomeThresholdM;
        if (outlierMadMultiplier != null) this.outlierMadMultiplier = outlierMadMultiplier;
        if (outlierMinDistanceM != null) this.outlierMinDistanceM = outlierMinDistanceM;
    }

    public record DeviceNearest(Long deviceId, Long farmId, Long livestockId,
                                String deviceCode, Double meters, Instant asOf) {
    }

    /** Latest-fix distance to the nearest registered gateway, or null when unknown. */
    public Double nearestGatewayDistance(Long deviceId) {
        List<GatewayLatestFix> fixes =
                deviceTelemetryLogRepository.findLatestFixesByGateway(deviceId, Instant.now().minus(FIX_WINDOW));
        GatewayLatestFix latest = fixes.stream()
                .filter(f -> f.latitude() != null && f.longitude() != null)
                .max(Comparator.comparing(GatewayLatestFix::reportTime))
                .orElse(null);
        if (latest == null || gatewayRegistryRepository.count() == 0) {
            return null;
        }
        Double best = null;
        for (GatewayRegistry registry : gatewayRegistryRepository.findAll()) {
            double meters = TrackLineCalculator.haversineMeters(
                    latest.latitude().doubleValue(), latest.longitude().doubleValue(),
                    registry.getLatitude().doubleValue(), registry.getLongitude().doubleValue());
            if (best == null || meters < best) {
                best = meters;
            }
        }
        return best;
    }

    /** F5 roll call: per-device check against the return-home threshold. */
    public void evaluateReturnHome() {
        for (DeviceNearest entry : activeDevicesWithDistance()) {
            if (entry.meters() == null) {
                continue;
            }
            if (entry.meters() > returnHomeThresholdM) {
                upsertScenarioAlert(entry, AlertType.RETURN_HOME, "alert.livestock.returnHome.v2");
            } else {
                resolveScenarioAlert(entry.deviceId(), AlertType.RETURN_HOME);
            }
        }
    }

    /**
     * F4 outlier watch: a device is flagged when its nearest-gateway distance
     * exceeds the farm baseline (median + MAD multiplier) AND the absolute
     * minimum distance — two animals never wander far apart (WiMOB 2019).
     * Farms with fewer than 3 located devices have no usable baseline.
     */
    public void evaluateOutliers() {
        Map<Long, List<DeviceNearest>> byFarm = groupActiveDevicesByFarm();
        for (Map.Entry<Long, List<DeviceNearest>> entry : byFarm.entrySet()) {
            List<Double> distances = entry.getValue().stream()
                    .map(DeviceNearest::meters)
                    .filter(d -> d != null)
                    .toList();
            if (distances.size() < 3) {
                continue;
            }
            double median = median(distances);
            List<Double> deviations = distances.stream()
                    .map(d -> Math.abs(d - median))
                    .sorted()
                    .toList();
            double mad = median(deviations);
            for (DeviceNearest device : entry.getValue()) {
                if (device.meters() == null) {
                    continue;
                }
                boolean outlier = isOutlier(device.meters(), median, mad,
                        outlierMadMultiplier, outlierMinDistanceM);
                if (outlier) {
                    upsertScenarioAlert(device, AlertType.OUTLIER, "alert.livestock.outlier.v2");
                } else {
                    resolveScenarioAlert(device.deviceId(), AlertType.OUTLIER);
                }
            }
        }
    }

    /** F6: aggregate yesterday's roaming radius for every active tracker. */
    public void aggregateRoamDaily(LocalDate day) {
        Instant from = day.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant to = day.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();
        for (Long deviceId : activeTrackerDeviceIds()) {
            List<Double> samples =
                    deviceTelemetryLogRepository.roamDistanceSamples(deviceId, from, to);
            if (samples.isEmpty()) {
                continue;
            }
            double max = samples.stream().mapToDouble(Double::doubleValue).max().orElse(0);
            double mean = samples.stream().mapToDouble(Double::doubleValue).average().orElse(0);
            livestockRoamRepository.save(new LivestockRoamDaily(
                    deviceId, day,
                    BigDecimal.valueOf(max).setScale(2, RoundingMode.HALF_UP),
                    BigDecimal.valueOf(mean).setScale(2, RoundingMode.HALF_UP),
                    samples.size()));
        }
    }

    public List<LivestockRoamDaily> roamHistory(Long deviceId, LocalDate from, LocalDate to) {
        return livestockRoamRepository.findByDeviceBetween(deviceId, from, to);
    }

    // --- helpers ---

    private List<DeviceNearest> activeDevicesWithDistance() {
        List<DeviceNearest> result = new ArrayList<>();
        for (DeviceNearest entry : activeDevicesByFarmFlat()) {
            Double meters = nearestGatewayDistance(entry.deviceId());
            result.add(new DeviceNearest(entry.deviceId(), entry.farmId(),
                    entry.livestockId(), entry.deviceCode(), meters, Instant.now()));
        }
        return result;
    }

    private Map<Long, List<DeviceNearest>> groupActiveDevicesByFarm() {
        Map<Long, List<DeviceNearest>> byFarm = new HashMap<>();
        for (DeviceNearest entry : activeDevicesByFarmFlat()) {
            if (entry.farmId() == null) {
                continue;
            }
            Double meters = nearestGatewayDistance(entry.deviceId());
            byFarm.computeIfAbsent(entry.farmId(), k -> new ArrayList<>())
                    .add(new DeviceNearest(entry.deviceId(), entry.farmId(),
                            entry.livestockId(), entry.deviceCode(), meters, Instant.now()));
        }
        return byFarm;
    }

    private List<DeviceNearest> activeDevicesByFarmFlat() {
        List<DeviceNearest> result = new ArrayList<>();
        for (var installation : installationRepository.findAllActive()) {
            Device device = deviceRepository.findById(installation.getDeviceId()).orElse(null);
            if (device == null || device.getDeviceType() != com.smartlivestock.iot.domain.model.DeviceType.TRACKER) {
                continue;
            }
            Long farmId = ranchQueryPort.findLivestockById(installation.getLivestockId())
                    .map(LivestockInfo::farmId).orElse(null);
            result.add(new DeviceNearest(device.getId(), farmId, installation.getLivestockId(),
                    device.getDeviceCode(), null, null));
        }
        return result;
    }

    private List<Long> activeTrackerDeviceIds() {
        return activeDevicesByFarmFlat().stream().map(DeviceNearest::deviceId).toList();
    }

    private void upsertScenarioAlert(DeviceNearest device, AlertType type, String messageKey) {
        if (device.farmId() == null) {
            return;
        }
        List<Alert> existing = alertRepository.findByDeviceIdAndTypeAndStatus(
                device.deviceId(), type, AlertStatus.ACTIVE);
        if (!existing.isEmpty()) {
            return;
        }
        int meters = (int) Math.round(device.meters());
        // livestockId is deliberately populated: it is the join key for the
        // estrus-score cross-check planned in NIX-156 (outlier + high estrus
        // score corroborate each other).
        Alert alert = new Alert(device.farmId(), device.livestockId(), null, device.deviceId(),
                type, Severity.WARNING,
                messageFallback(type, device.deviceCode(), meters));
        alert.setMessageKey(messageKey);
        alert.setMessageArgs(toJson(List.of(device.deviceCode(), meters)));
        alertRepository.save(alert);
    }

    private void resolveScenarioAlert(Long deviceId, AlertType type) {
        alertRepository.findByDeviceIdAndTypeAndStatus(deviceId, type, AlertStatus.ACTIVE)
                .forEach(alert -> {
                    alert.autoResolve();
                    alertRepository.save(alert);
                });
    }

    private String messageFallback(AlertType type, String deviceCode, int meters) {
        String template = type == AlertType.OUTLIER
                ? "牲畜离群: %s 距最近网关约%d米"
                : "未归提醒: %s 距场区约%d米";
        return String.format(template, deviceCode, meters);
    }

    /** Pure outlier decision (unit-tested): beyond farm baseline AND the absolute floor. */
    static boolean isOutlier(double distanceM, double median, double mad,
                             double madMultiplier, double minDistanceM) {
        return distanceM > median + madMultiplier * mad
                && distanceM > minDistanceM;
    }

    private double median(List<Double> values) {
        List<Double> sorted = new ArrayList<>(values);
        sorted.sort(Comparator.naturalOrder());
        int n = sorted.size();
        return n % 2 == 1
                ? sorted.get(n / 2)
                : (sorted.get(n / 2 - 1) + sorted.get(n / 2)) / 2.0;
    }

    private String toJson(List<?> args) {
        try {
            return objectMapper.writeValueAsString(args);
        } catch (Exception e) {
            return "[]";
        }
    }
}
