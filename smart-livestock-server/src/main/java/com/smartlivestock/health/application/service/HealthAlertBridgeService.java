package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import com.smartlivestock.identity.application.TenantZoneResolver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
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
 * <p>
 * The calving rule (NIX-381, {@link #syncCalvingAlert}) also colors the map
 * (calving_risk_score >= 70), but its ticket follows a persistence +
 * hysteresis state machine owned by the calving evaluation: the marker may
 * lead the ticket by one evaluation (first crossing) and trail it inside the
 * 55–70 hold band.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HealthAlertBridgeService {

    private static final int ESTRUS_ALERT_THRESHOLD = 70;
    private static final String TYPE_TEMPERATURE = "TEMPERATURE_ABNORMAL";
    private static final String TYPE_DIGESTIVE = "DIGESTIVE_ABNORMAL";
    private static final String TYPE_ESTRUS = "ESTRUS";
    private static final String TYPE_CALVING = "CALVING_WARNING";
    /** Expected-calving-window display format in the farm zone: digits only,
     *  so one rendered text serves both locales (messageArgs are frozen). */
    private static final DateTimeFormatter CALVING_WINDOW_FORMAT =
            DateTimeFormatter.ofPattern("MM-dd HH:mm", Locale.ROOT);

    private final RanchQueryPort ranchQueryPort;
    private final RanchCommandPort ranchCommandPort;
    private final TenantZoneResolver tenantZoneResolver;
    private final CalvingPredictionProperties calvingProperties;

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
    }

    /**
     * Raise or resolve the CALVING_WARNING ticket of one livestock (NIX-381).
     * Not part of {@link #syncAlertsWithSnapshot}: the calving state machine
     * (persistence + 70/55 hysteresis) lives in the calving evaluation, which
     * calls this only on a transition — raise after the score persisted at or
     * above the alert threshold, release once it fell below the release
     * threshold; zero calls otherwise.
     * <p>
     * Plain parameters on purpose: the caller's targeted snapshot UPDATE
     * clears the persistence context, so nothing here may rely on a managed
     * snapshot entity.
     *
     * @param score         evaluated score; at/above the alert threshold
     *                      raises (deduplicated against an ACTIVE ticket),
     *                      anything else (null included) resolves
     * @param windowDisplay formatted expected calving window, or null to keep
     *                      the window out of the alert text (prior conflict /
     *                      no estimate)
     * @param source        telemetry source; DATAGEN stays DATAGEN, anything
     *                      else becomes RULE
     */
    public void syncCalvingAlert(Long farmId, Long livestockId, Integer score,
                                 String windowDisplay, String source) {
        boolean alarming = score != null && score >= calvingProperties.getAlertThreshold();
        if (!alarming) {
            ranchCommandPort.resolveAlert(livestockId, TYPE_CALVING);
            return;
        }
        if (ranchQueryPort.hasActiveAlert(livestockId, TYPE_CALVING)) return;

        String code = livestockCode(livestockId);
        String scoreText = String.valueOf(score);
        AlertInfo info;
        if (windowDisplay != null) {
            String message = String.format("牲畜 [%s] 临产风险偏高：%s 分，预计分娩窗口 %s",
                    code, scoreText, windowDisplay);
            info = new AlertInfo(farmId, livestockId, TYPE_CALVING, "WARNING", message, mapSource(source),
                    "alert.health.calving.window", List.of(code, scoreText, windowDisplay));
        } else {
            String message = String.format("牲畜 [%s] 临产风险偏高：%s 分", code, scoreText);
            info = new AlertInfo(farmId, livestockId, TYPE_CALVING, "WARNING", message, mapSource(source),
                    "alert.health.calving", List.of(code, scoreText));
        }
        ranchCommandPort.createAlert(info);
        log.info("Created {} alert for livestock [{}] (calving score={})", TYPE_CALVING, livestockId, score);
    }

    /**
     * {@link #syncCalvingAlert(Long, Long, Integer, String, String)} with the
     * window still as instants: formats it in the farm zone first. A missing
     * bound or an empty / inverted window leaves the window out of the text.
     */
    public void syncCalvingAlert(Long farmId, Long livestockId, Integer score,
                                 Instant windowStart, Instant windowEnd, String source) {
        syncCalvingAlert(farmId, livestockId, score,
                formatCalvingWindow(farmId, windowStart, windowEnd), source);
    }

    /**
     * {@code "MM-dd HH:mm ~ MM-dd HH:mm"} in the farm zone (farm → tenant →
     * platform default → UTC; never null without a client offset). Null when
     * a bound is missing or the window is empty or inverted.
     */
    private String formatCalvingWindow(Long farmId, Instant start, Instant end) {
        if (start == null || end == null || !start.isBefore(end)) {
            return null;
        }
        ZoneId zone = tenantZoneResolver.zoneForFarm(farmId, null);
        return CALVING_WINDOW_FORMAT.format(start.atZone(zone))
                + " ~ " + CALVING_WINDOW_FORMAT.format(end.atZone(zone));
    }

    /** DATAGEN telemetry keeps its source on the ticket; everything else is a rule alert. */
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
