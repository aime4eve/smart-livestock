package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.model.TemperatureLog;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Analyzes temperature logs to detect fever conditions.
 * Rules:
 *   delta < 1.0°C           → NORMAL
 *   1.0 ≤ delta < 1.5°C     → ELEVATED (if sustained < 2h)
 *   delta ≥ 1.5°C OR sustained > 2h → FEVER
 *   delta ≥ 2.0°C OR temp ≥ 41.0°C  → CRITICAL
 */
@Service
public class FeverAnalysisService {

    private static final BigDecimal FEVER_THRESHOLD = new BigDecimal("1.0");
    private static final BigDecimal HIGH_FEVER_THRESHOLD = new BigDecimal("1.5");
    private static final BigDecimal CRITICAL_DELTA = new BigDecimal("2.0");
    private static final BigDecimal CRITICAL_TEMP = new BigDecimal("41.0");
    private static final Duration SUSTAINED_DURATION = Duration.ofHours(2);

    public TempStatus assessStatus(TemperatureLog latest, List<TemperatureLog> recentLogs) {
        if (latest == null || latest.getDelta() == null) {
            return TempStatus.NORMAL;
        }

        BigDecimal delta = latest.getDelta();

        if (delta.compareTo(CRITICAL_DELTA) >= 0 || latest.getTemperature().compareTo(CRITICAL_TEMP) >= 0) {
            return TempStatus.CRITICAL;
        }

        if (delta.compareTo(HIGH_FEVER_THRESHOLD) >= 0) {
            return TempStatus.FEVER;
        }

        if (delta.compareTo(FEVER_THRESHOLD) >= 0) {
            boolean sustained = isSustainedElevation(recentLogs, FEVER_THRESHOLD);
            return sustained ? TempStatus.FEVER : TempStatus.ELEVATED;
        }

        return TempStatus.NORMAL;
    }

    public String generateConclusion(TempStatus status, BigDecimal delta, Duration duration) {
        return switch (status) {
            case CRITICAL -> "体温严重偏高" + formatDuration(duration) + "，建议立即隔离并联系兽医";
            case FEVER -> "体温持续偏高超过" + formatDuration(duration) + "，建议隔离观察";
            case ELEVATED -> "体温轻微升高，建议持续观察";
            case NORMAL -> "体温正常";
        };
    }

    private boolean isSustainedElevation(List<TemperatureLog> logs, BigDecimal threshold) {
        if (logs == null || logs.size() < 2) return false;

        Instant firstElevated = null;
        for (int i = logs.size() - 1; i >= 0; i--) {
            TemperatureLog log = logs.get(i);
            if (log.getDelta() != null && log.getDelta().compareTo(threshold) >= 0) {
                if (firstElevated == null) firstElevated = log.getRecordedAt();
            } else {
                break;
            }
        }

        if (firstElevated == null) return false;
        Instant latestTime = logs.get(logs.size() - 1).getRecordedAt();
        return Duration.between(firstElevated, latestTime).compareTo(SUSTAINED_DURATION) >= 0;
    }

    private String formatDuration(Duration duration) {
        if (duration == null) return "";
        long hours = duration.toHours();
        if (hours < 1) return "不到 1 小时";
        return " " + hours + " 小时";
    }
}
