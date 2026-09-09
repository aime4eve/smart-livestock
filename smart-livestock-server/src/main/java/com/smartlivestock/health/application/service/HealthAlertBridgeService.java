package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.function.Supplier;

/**
 * Bridges health snapshot rule states to Ranch alert tickets.
 * <p>
 * The ranch map colors a livestock marker exactly when one of the rule states
 * below fires (see RanchOverviewApplicationService.deriveHealthStatus), so each
 * fired state must have an ACTIVE alert ticket and each cleared state must not —
 * otherwise the map shows warnings while the alert center stays empty.
 * <p>
 * Dedup + auto-resolve mirror the fence alert pattern in GpsLogEventConsumer:
 * create only when no ACTIVE ticket of the same type exists; auto-resolve when
 * the rule state clears. Callers gate on state transitions, so steady-state
 * telemetry costs nothing.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HealthAlertBridgeService {

    private static final int ESTRUS_ALERT_THRESHOLD = 70;
    private static final String TYPE_TEMPERATURE = "TEMPERATURE_ABNORMAL";
    private static final String TYPE_DIGESTIVE = "DIGESTIVE_ABNORMAL";
    private static final String TYPE_ESTRUS = "ESTRUS";

    private final RanchQueryPort ranchQueryPort;
    private final RanchCommandPort ranchCommandPort;

    /**
     * Whether the snapshot crossed a rule threshold since the previous
     * assessment. Compares alarming flags (not raw values) so score
     * fluctuations below the threshold do not trigger ticket queries.
     * Callers gate {@link #syncAlertsWithSnapshot} on this, keeping
     * steady-state telemetry free of alert lookups.
     */
    public static boolean hasStateChanged(HealthSnapshot snapshot,
                                          TempStatus prevTempStatus,
                                          MotilityStatus prevMotilityStatus,
                                          Integer prevEstrusScore) {
        return snapshot.getTempStatus() != prevTempStatus
                || snapshot.getMotilityStatus() != prevMotilityStatus
                || isEstrusAlarming(snapshot.getEstrusScore()) != isEstrusAlarming(prevEstrusScore);
    }

    /**
     * Reconcile all three rule dimensions of a snapshot with alert tickets.
     */
    public void syncAlertsWithSnapshot(HealthSnapshot snapshot, String source) {
        syncTemperatureAlert(snapshot, source);
        syncDigestiveAlert(snapshot, source);
        syncEstrusAlert(snapshot, source);
    }

    private void syncTemperatureAlert(HealthSnapshot snapshot, String source) {
        TempStatus status = snapshot.getTempStatus();
        boolean alarming = status == TempStatus.ELEVATED
                || status == TempStatus.FEVER
                || status == TempStatus.CRITICAL;
        String severity = status == TempStatus.CRITICAL ? "CRITICAL" : "WARNING";
        syncRule(snapshot, source, TYPE_TEMPERATURE, alarming, () -> {
            String code = livestockCode(snapshot.getLivestockId());
            String current = plain(snapshot.getCurrentTemp());
            String baseline = plain(snapshot.getBaselineTemp());
            String message = String.format("牲畜 [%s] 体温异常：当前 %s°C，基线 %s°C", code, current, baseline);
            return new AlertInfo(snapshot.getFarmId(), snapshot.getLivestockId(),
                    TYPE_TEMPERATURE, severity, message, mapSource(source),
                    "alert.health.temperature", List.of(code, current, baseline));
        });
    }

    private void syncDigestiveAlert(HealthSnapshot snapshot, String source) {
        boolean alarming = snapshot.getMotilityStatus() == MotilityStatus.ABNORMAL;
        syncRule(snapshot, source, TYPE_DIGESTIVE, alarming, () -> {
            String code = livestockCode(snapshot.getLivestockId());
            String current = plain(snapshot.getCurrentMotility());
            String baseline = plain(snapshot.getMotilityBaseline());
            String message = String.format("牲畜 [%s] 瘤胃运动异常：当前 %s，基线 %s", code, current, baseline);
            return new AlertInfo(snapshot.getFarmId(), snapshot.getLivestockId(),
                    TYPE_DIGESTIVE, "WARNING", message, mapSource(source),
                    "alert.health.digestive", List.of(code, current, baseline));
        });
    }

    private void syncEstrusAlert(HealthSnapshot snapshot, String source) {
        boolean alarming = isEstrusAlarming(snapshot.getEstrusScore());
        syncRule(snapshot, source, TYPE_ESTRUS, alarming, () -> {
            String code = livestockCode(snapshot.getLivestockId());
            String score = String.valueOf(snapshot.getEstrusScore());
            String message = String.format("牲畜 [%s] 发情评分偏高：%s 分", code, score);
            return new AlertInfo(snapshot.getFarmId(), snapshot.getLivestockId(),
                    TYPE_ESTRUS, "WARNING", message, mapSource(source),
                    "alert.health.estrus", List.of(code, score));
        });
    }

    private void syncRule(HealthSnapshot snapshot, String source, String alertType,
                          boolean alarming, Supplier<AlertInfo> infoSupplier) {
        if (alarming) {
            if (ranchQueryPort.hasActiveAlert(snapshot.getLivestockId(), alertType)) return;
            ranchCommandPort.createAlert(infoSupplier.get());
            log.info("Created {} alert for livestock [{}] from health snapshot", alertType, snapshot.getLivestockId());
        } else {
            ranchCommandPort.resolveAlert(snapshot.getLivestockId(), alertType);
        }
    }

    private static boolean isEstrusAlarming(Integer estrusScore) {
        return estrusScore != null && estrusScore >= ESTRUS_ALERT_THRESHOLD;
    }    /** DATAGEN telemetry keeps its source on the ticket; everything else is a rule alert. */
    private String mapSource(String source) {
        return "DATAGEN".equals(source) ? "DATAGEN" : "RULE";
    }

    private String livestockCode(Long livestockId) {
        return ranchQueryPort.findLivestockById(livestockId)
                .map(LivestockInfo::livestockCode)
                .orElse("?");
    }

    private String plain(BigDecimal value) {
        return value != null ? value.toPlainString() : "?";
    }
}
