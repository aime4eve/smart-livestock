package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.model.TemperatureLog;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class FeverAnalysisServiceTest {

    private final FeverAnalysisService service = new FeverAnalysisService();

    private TemperatureLog log(String temperature, String baseline, String delta, Instant recordedAt) {
        TemperatureLog log = new TemperatureLog();
        log.setTemperature(temperature != null ? new BigDecimal(temperature) : null);
        log.setBaselineTemp(baseline != null ? new BigDecimal(baseline) : null);
        log.setDelta(delta != null ? new BigDecimal(delta) : null);
        log.setRecordedAt(recordedAt);
        return log;
    }

    @Test
    void persistedDelta_critical() {
        TempStatus status = service.assessStatus(
                log("41.20", "38.50", "2.70", Instant.now()), List.of());
        assertEquals(TempStatus.CRITICAL, status);
    }

    @Test
    void missingDelta_derivedFromTemperatureMinusBaseline_sameTransactionInsert() {
        // Just-inserted row inside the same persistence context: generated delta is null
        TemperatureLog latest = log("41.20", "38.50", null, Instant.now());
        assertEquals(TempStatus.CRITICAL, service.assessStatus(latest, List.of(latest)));
    }

    @Test
    void missingDelta_elevatedWhenNotSustained() {
        TemperatureLog latest = log("39.60", "38.50", null, Instant.now());
        TemperatureLog older = log("38.40", "38.50", "-0.10", Instant.now().minusSeconds(300));
        assertEquals(TempStatus.ELEVATED, service.assessStatus(latest, List.of(latest, older)));
    }

    @Test
    void missingDelta_feverWhenSustained() {
        Instant now = Instant.now();
        TemperatureLog latest = log("39.80", "38.50", null, now);
        TemperatureLog mid = log("39.70", "38.50", "1.20", now.minusSeconds(3600));
        TemperatureLog first = log("39.60", "38.50", "1.10", now.minusSeconds(7200));
        // Sustained ≥1.0 delta for ≥2h (mid + first carry real deltas) → FEVER
        assertEquals(TempStatus.FEVER, service.assessStatus(latest, List.of(latest, mid, first)));
    }

    @Test
    void sustainedDetection_isOrderAgnostic() {
        // Historical bug: measured against the wrong end of a newest-first list
        Instant now = Instant.now();
        TemperatureLog latest = log("39.80", "38.50", "1.30", now);
        TemperatureLog mid = log("39.70", "38.50", "1.20", now.minusSeconds(3600));
        TemperatureLog first = log("39.60", "38.50", "1.10", now.minusSeconds(7200));
        assertEquals(TempStatus.FEVER, service.assessStatus(latest, List.of(first, mid, latest)));
    }

    @Test
    void missingDeltaAndMissingBaseline_returnsNormal() {
        TemperatureLog latest = log("41.20", null, null, Instant.now());
        assertEquals(TempStatus.NORMAL, service.assessStatus(latest, List.of()));
    }

    @Test
    void normalTemperature_returnsNormal() {
        TemperatureLog latest = log("38.40", "38.50", null, Instant.now());
        assertEquals(TempStatus.NORMAL, service.assessStatus(latest, List.of(latest)));
    }

    @Test
    void absoluteHighTemperature_criticalRegardlessOfDelta() {
        TemperatureLog latest = log("41.10", "38.50", "2.60", Instant.now());
        assertEquals(TempStatus.CRITICAL, service.assessStatus(latest, List.of(latest)));
    }
}
