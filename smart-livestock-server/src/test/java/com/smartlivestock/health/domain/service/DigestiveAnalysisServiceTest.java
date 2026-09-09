package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.MotilityStatus;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

class DigestiveAnalysisServiceTest {

    private final DigestiveAnalysisService service = new DigestiveAnalysisService();

    private MotilityStatus assess(String freq, String baseline) {
        return service.assessStatus(new BigDecimal(freq),
                baseline != null ? new BigDecimal(baseline) : null);
    }

    @Test
    void clinicalFloor_guardrail_preventsFalseAbnormalOnSlowButHealthyCattle() {
        // baseline 3.0: old line 1.5 flagged healthy 1.0–1.5/min cattle (literature
        // normal band 1–3/min). Guardrail min(0.5×baseline, 1.0) caps the line at 1.0.
        assertEquals(MotilityStatus.LOW, assess("1.40", "3.0"));
        assertEquals(MotilityStatus.LOW, assess("1.00", "3.0"));
        assertEquals(MotilityStatus.ABNORMAL, assess("0.99", "3.0"));
    }

    @Test
    void highBaseline_abnormalLineCappedAtClinicalFloor() {
        assertEquals(MotilityStatus.LOW, assess("1.20", "4.0"));
        assertEquals(MotilityStatus.ABNORMAL, assess("0.95", "4.0"));
    }

    @Test
    void lowBaseline_relativeRuleStillWinsBelowFloor() {
        // baseline 1.5: 0.5×1.5=0.75 < floor 1.0, relative drop governs
        assertEquals(MotilityStatus.ABNORMAL, assess("0.70", "1.5"));
        assertEquals(MotilityStatus.LOW, assess("0.90", "1.5"));
    }

    @Test
    void defaultBaseline_twoContractionBand() {
        // default now 2.0 (mid of 1–3 literature band)
        assertEquals(MotilityStatus.NORMAL, assess("1.50", null));
        assertEquals(MotilityStatus.LOW, assess("1.30", null));
        assertEquals(MotilityStatus.ABNORMAL, assess("0.90", null));
    }

    @Test
    void normalBand_unchanged() {
        assertEquals(MotilityStatus.NORMAL, assess("3.00", "3.0"));
        assertEquals(MotilityStatus.NORMAL, assess("2.50", "3.0"));
        assertEquals(MotilityStatus.LOW, assess("2.00", "3.0"));
    }

    @Test
    void nullFrequency_normal() {
        assertEquals(MotilityStatus.NORMAL, service.assessStatus(null, new BigDecimal("3.0")));
    }
}
