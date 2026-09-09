package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.model.TemperatureLog;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
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
        if (latest == null) {
            return TempStatus.NORMAL;
        }

        BigDecimal delta = effectiveDelta(latest);
        if (delta == null) {
            return TempStatus.NORMAL;
        }

        if (delta.compareTo(CRITICAL_DELTA) >= 0 || latest.getTemperature().compareTo(CRITICAL_TEMP) >= 0) {
            return TempStatus.CRITICAL;
        }

        if (delta.compareTo(HIGH_FEVER_THRESHOLD) >= 0) {
            return TempStatus.FEVER;
        }

        if (delta.compareTo(FEVER_THRESHOLD) >= 0) {
            boolean sustained = isSustainedElevation(recentLogs, FEVER_THRESHOLD, latest.getRecordedAt());
            return sustained ? TempStatus.FEVER : TempStatus.ELEVATED;
        }

        return TempStatus.NORMAL;
    }

    /**
     * delta is a DB-generated column (temperature - baseline_temp) that is not
     * populated on the just-inserted entity within the same persistence context,
     * so derive it from its definition when missing — otherwise live fever
     * assessment silently degrades to NORMAL.
     */
    private static BigDecimal effectiveDelta(TemperatureLog log) {
        if (log.getDelta() != null) return log.getDelta();
        if (log.getTemperature() == null || log.getBaselineTemp() == null) return null;
        return log.getTemperature().subtract(log.getBaselineTemp());
    }

   public String generateConclusion(TempStatus status, BigDecimal delta, Duration duration) {
       return switch (status) {
            case CRITICAL -> "Severely elevated temperature for" + formatDuration(duration) + ". Isolate immediately and contact a veterinarian.";
            case FEVER -> "Temperature sustained high for" + formatDuration(duration) + ". Isolate and monitor.";
            case ELEVATED -> "Slightly elevated temperature. Continue monitoring.";
            case NORMAL -> "Temperature normal";
       };
   }

    /**
     * Recent logs arrive newest-first, but the historical implementation walked
     * them assuming oldest-first and measured against the oldest row, so a ≥2h
     * sustained elevation could never be detected. Sort explicitly and measure
     * from the start of the trailing elevated run to the latest reading.
     */
    private boolean isSustainedElevation(List<TemperatureLog> logs, BigDecimal threshold, Instant latestTime) {
        if (logs == null || logs.size() < 2 || latestTime == null) return false;

        List<TemperatureLog> byRecordedAtDesc = logs.stream()
                .filter(l -> l.getRecordedAt() != null)
                .sorted(Comparator.comparing(TemperatureLog::getRecordedAt).reversed())
                .toList();

        Instant firstElevated = null;
        for (TemperatureLog log : byRecordedAtDesc) {
            BigDecimal delta = effectiveDelta(log);
            if (delta != null && delta.compareTo(threshold) >= 0) {
                firstElevated = log.getRecordedAt();
            } else {
                break;
            }
        }

        if (firstElevated == null) return false;
        return Duration.between(firstElevated, latestTime).compareTo(SUSTAINED_DURATION) >= 0;
    }

   private String formatDuration(Duration duration) {
       if (duration == null) return "";
       long hours = duration.toHours();
        if (hours < 1) return " less than 1 hour";
        return " " + hours + " hours";
   }
}
