package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.GatewayLatestFix;
import com.smartlivestock.iot.domain.model.GatewayRegistry;
import com.smartlivestock.iot.domain.model.GatewayUsageSummary;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.GatewayRegistryRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Gateway position registry application service (NIX-219).
 * Discovery lists the gateways a farm's devices actually talk to; marking is
 * a globally-unique upsert where a later marker overwrites the earlier one.
 */
@Service
@RequiredArgsConstructor
public class GatewayRegistryService {

    private static final Duration DISCOVERY_WINDOW = Duration.ofDays(90);
    private static final String DATAGEN_GATEWAY = "datagen-gw-01";
    private static final String SOURCE_APP = "APP";

    private final GatewayRegistryRepository gatewayRegistryRepository;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final RanchQueryPort ranchQueryPort;
    private final InstallationRepository installationRepository;

    public record GatewayDiscoveryItem(
            String gatewayId,
            Instant lastSeen,
            long frames,
            Double avgRssi,
            boolean registered,
            BigDecimal latitude,
            BigDecimal longitude,
            Instant markedAt) {

        /** F3 tier from the 30-day average RSSI (matches DeviceLinkQualityService cuts). */
        public String linkTier() {
            if (avgRssi == null) return "unknown";
            if (avgRssi < -100) return "edge";
            if (avgRssi < -90) return "weak";
            return "stable";
        }
    }

    public record MarkResult(
            boolean overwritten,
            Long previousMarkedBy,
            Instant previousMarkedAt,
            GatewayRegistry registry) {
    }

    public record AdminGatewayOverview(
            List<GatewayRegistry> registered,
            List<String> unmarked,
            long seenGatewayCount,
            double markRate) {
    }

    /** Gateways the farm's actively-installed devices actually communicated with. */
    public List<GatewayDiscoveryItem> discoverFarmGateways(Long farmId) {
        List<Long> deviceIds = farmDeviceIds(farmId);
        if (deviceIds.isEmpty()) {
            return List.of();
        }
        Instant since = Instant.now().minus(DISCOVERY_WINDOW);
        // Synthetic gateways never belong to a real pasture view (F10 parity).
        List<GatewayUsageSummary> usage =
                deviceTelemetryLogRepository.aggregateGatewayUsage(deviceIds, since).stream()
                        .filter(u -> !DATAGEN_GATEWAY.equals(u.gatewayId()))
                        .toList();
        return usage.stream()
                .sorted((a, b) -> b.lastSeen().compareTo(a.lastSeen()))
                .map(u -> {
                    GatewayRegistry reg = gatewayRegistryRepository.findByGatewayId(u.gatewayId()).orElse(null);
                    return new GatewayDiscoveryItem(
                            u.gatewayId(), u.lastSeen(), u.frames(), u.avgRssi(),
                            reg != null,
                            reg != null ? reg.getLatitude() : null,
                            reg != null ? reg.getLongitude() : null,
                            reg != null ? reg.getMarkedAt() : null);
                })
                .toList();
    }

    /**
     * Globally-unique position upsert. When a position already exists it is
     * overwritten (UI confirms first); the previous marker is reported back.
     */
    public MarkResult markPosition(String gatewayId, double latitude, double longitude,
                                   Long markedBy, String source) {
        if (gatewayId == null || gatewayId.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "gatewayId 不能为空");
        }
        if (Math.abs(latitude) > 90 || Math.abs(longitude) > 180
                || (latitude == 0 && longitude == 0)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "坐标非法: " + latitude + "," + longitude);
        }
        GatewayRegistry existing = gatewayRegistryRepository.findByGatewayId(gatewayId).orElse(null);

        GatewayRegistry registry = existing != null ? existing : new GatewayRegistry();
        MarkResult result = new MarkResult(
                existing != null,
                existing != null ? existing.getMarkedBy() : null,
                existing != null ? existing.getMarkedAt() : null,
                registry);
        registry.setGatewayId(gatewayId);
        registry.setLatitude(BigDecimal.valueOf(latitude));
        registry.setLongitude(BigDecimal.valueOf(longitude));
        registry.setMarkedBy(markedBy);
        registry.setMarkedAt(Instant.now());
        registry.setSource(source != null ? source : SOURCE_APP);
        gatewayRegistryRepository.save(registry);
        return result;
    }

    /** F10: registry list + gateways seen in telemetry but never marked + mark rate. */
    public AdminGatewayOverview adminOverview() {
        List<GatewayRegistry> registered = gatewayRegistryRepository.findAll();
        Set<String> registeredIds = new HashSet<>();
        registered.forEach(r -> registeredIds.add(r.getGatewayId()));

        Instant since = Instant.now().minus(DISCOVERY_WINDOW);
        List<String> unmarked = new ArrayList<>(deviceTelemetryLogRepository
                .findDistinctGatewayIds(since).stream()
                .filter(id -> !DATAGEN_GATEWAY.equals(id) && !registeredIds.contains(id))
                .toList());
        long seen = registered.size() + unmarked.size();
        double rate = seen == 0 ? 1.0 : (double) registered.size() / seen;
        return new AdminGatewayOverview(registered, unmarked, seen, rate);
    }

    /** Latest known position of a gateway, for consumers needing raw coordinates. */
    public GatewayRegistry requirePosition(String gatewayId) {
        return gatewayRegistryRepository.findByGatewayId(gatewayId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "网关未登记: " + gatewayId));
    }

    /** Latest valid fix per gateway for one device — basis of "nearest gateway". */
    public List<GatewayLatestFix> latestFixes(Long deviceId) {
        return deviceTelemetryLogRepository.findLatestFixesByGateway(
                deviceId, Instant.now().minus(DISCOVERY_WINDOW));
    }

    public List<Long> farmDeviceIds(Long farmId) {
        List<Long> livestockIds = ranchQueryPort.findAllByFarmId(farmId).stream()
                .map(LivestockInfo::id)
                .toList();
        if (livestockIds.isEmpty()) {
            return List.of();
        }
        return installationRepository.findByLivestockIdIn(livestockIds).stream()
                .filter(inst -> inst.getRemovedAt() == null)
                .map(inst -> inst.getDeviceId())
                .distinct()
                .toList();
    }
}
