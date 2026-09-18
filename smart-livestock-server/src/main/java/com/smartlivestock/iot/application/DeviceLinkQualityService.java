package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.LinkQualityStats;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
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

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Link quality tiering and edge warning (NIX-219 F3). A device is tiered per
 * receiving gateway over its most recent frames; EDGE triggers a LINK_QUALITY
 * alert (deduplicated like other device alerts), recovery back to STABLE
 * auto-resolves it. Evidence: before the 2026-09-14 gateway outage the affected
 * collars were already averaging around -105 dBm — weak link precedes silence.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceLinkQualityService {

    private static final Duration WINDOW = Duration.ofDays(30);
    private static final int LIMIT_FRAMES = 30;

    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final AlertRepository alertRepository;
    private final ObjectMapper objectMapper;

    @Value("${smartlivestock.link-quality.weak-threshold:-90}")
    private double weakThreshold;

    @Value("${smartlivestock.link-quality.edge-threshold:-100}")
    private double edgeThreshold;

    /**
     * Evaluate one ingested frame's gateway link. Called only for live sources
     * with a non-blank gateway id. farmId null (unassigned device) skips alert
     * creation — alerts.farm_id is NOT NULL and a null would abort ingestion.
     */
    public void evaluate(Device device, Long farmId, String gatewayId) {
        if (gatewayId == null || gatewayId.isBlank()) {
            return;
        }
        LinkQualityStats stats = deviceTelemetryLogRepository
                .recentLinkQuality(device.getId(), gatewayId, Instant.now().minus(WINDOW), LIMIT_FRAMES)
                .orElse(null);
        if (stats == null) {
            return;
        }
        LinkQualityStats.Tier tier = stats.tier(weakThreshold, edgeThreshold);
        if (tier == LinkQualityStats.Tier.EDGE) {
            createEdgeAlertIfNotExists(device, farmId, gatewayId, stats);
        } else if (tier == LinkQualityStats.Tier.STABLE) {
            autoResolveEdgeAlert(device);
        }
    }

    private void createEdgeAlertIfNotExists(Device device, Long farmId, String gatewayId,
                                            LinkQualityStats stats) {
        if (farmId == null) {
            log.debug("skip LINK_QUALITY alert: device {} has no farm", device.getId());
            return;
        }
        List<Alert> existing = alertRepository.findByDeviceIdAndTypeAndStatus(
                device.getId(), AlertType.LINK_QUALITY, AlertStatus.ACTIVE);
        if (!existing.isEmpty()) {
            return;
        }
        String message = "设备信号弱: " + device.getDeviceCode()
                + " 网关" + gatewayId + " 平均RSSI " + String.format("%.0f", stats.avgRssi()) + "dBm";
        Alert alert = new Alert(farmId, null, null, device.getId(),
                AlertType.LINK_QUALITY, Severity.WARNING, message);
        alert.setMessageKey("alert.device.linkQuality.v2");
        alert.setMessageArgs(toJson(List.of(device.getDeviceCode(), gatewayId,
                (int) Math.round(stats.avgRssi()))));
        alertRepository.save(alert);
    }

    private void autoResolveEdgeAlert(Device device) {
        alertRepository.findByDeviceIdAndTypeAndStatus(
                        device.getId(), AlertType.LINK_QUALITY, AlertStatus.ACTIVE)
                .forEach(alert -> {
                    alert.autoResolve();
                    alertRepository.save(alert);
                });
    }

    private String toJson(List<?> args) {
        try {
            return objectMapper.writeValueAsString(args);
        } catch (Exception e) {
            return "[]";
        }
    }
}
