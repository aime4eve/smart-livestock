package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.governance.TelemetryValidationRule;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.GpsQualityFlagSummary;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.repository.GpsQualityFlagRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Data-governance entry point (NIX-220): evaluates registered validation rules
 * per ingested frame and persists aggregate flag counters. Raw frames are never
 * modified or dropped here — consumers (distance, trajectory, fence) read flags
 * or pre-filtered paths.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GpsDataGovernanceService {

    static final String RULE_GPS_COORD_RANGE = "gps_coord_range";
    static final String RULE_GPS_NO_FIX = "gps_no_fix";

    private final List<TelemetryValidationRule> rules;
    private final GpsQualityFlagRepository gpsQualityFlagRepository;

    /**
     * Evaluate all registered rules for one frame and persist flags.
     *
     * @return names of the rules the frame violated (empty when clean)
     */
    public List<String> evaluateAndFlag(DeviceType deviceType, TelemetrySource source,
                                        Long deviceId, Map<String, Object> readings, Instant recordedAt) {
        List<String> flagged = new ArrayList<>();
        // Synthetic data must not pollute quality metrics (AGENTS.md §2).
        if (source == TelemetrySource.DATAGEN) {
            return flagged;
        }
        for (TelemetryValidationRule rule : rules) {
            rule.validate(readings, source, deviceType).ifPresent(reason -> {
                flagged.add(rule.name());
                try {
                    gpsQualityFlagRepository.increment(
                            deviceId, rule.name(),
                            JpaGpsQualityFlagDay.toUtcDay(recordedAt), reason);
                } catch (RuntimeException e) {
                    // Flag bookkeeping must never break ingestion.
                    log.warn("governance flag persist failed: device={} rule={} err={}",
                            deviceId, rule.name(), e.getMessage());
                }
            });
        }
        if (!flagged.isEmpty()) {
            log.debug("governance flags {}: device={}", flagged, deviceId);
        }
        return flagged;
    }

    /** Whether the flagged set marks the coordinates unusable for geometric consumers. */
    public static boolean hasCoordFlag(List<String> flaggedRules) {
        return flaggedRules.contains(RULE_GPS_COORD_RANGE) || flaggedRules.contains(RULE_GPS_NO_FIX);
    }

    public List<GpsQualityFlagSummary> summarize(Instant from, Instant to) {
        return gpsQualityFlagRepository.summarize(from, to);
    }

    public List<GpsQualityFlagSummary> summarizeByDevice(Instant from, Instant to) {
        return gpsQualityFlagRepository.summarizeByDevice(from, to);
    }

    /** Day conversion shim so the application layer does not depend on the adapter. */
    private static final class JpaGpsQualityFlagDay {
        static java.time.LocalDate toUtcDay(Instant instant) {
            return instant == null
                    ? java.time.LocalDate.now(java.time.ZoneOffset.UTC)
                    : instant.atZone(java.time.ZoneOffset.UTC).toLocalDate();
        }
    }
}
