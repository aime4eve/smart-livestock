package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.RumenMotilityLog;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * Analyzes rumen motility logs to detect digestive issues.
 * Rules (calibrated against clinical reference 1–3 contractions/min, see
 * docs/calibration/2026-09-10-bolus-activity-threshold-report.md):
 *   frequency ≥ baseline × 0.7              → NORMAL
 *   baseline × 0.5 ≤ frequency < baseline × 0.7 → LOW
 *   frequency < baseline × 0.5              → ABNORMAL
 * Clinical floor guard: a healthy animal can contract as slowly as the
 * literature lower bound, so the ABNORMAL line never rises above it —
 * min(0.5 × baseline, FLOOR) prevents mis-flagging slow-but-normal cattle.
 */
@Service
public class DigestiveAnalysisService {

    private static final BigDecimal LOW_RATIO = new BigDecimal("0.7");
    private static final BigDecimal ABNORMAL_RATIO = new BigDecimal("0.5");
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("2.0");
    /** Literature lower bound of healthy rumen motility (contractions/min). */
    static final BigDecimal CLINICAL_FLOOR = new BigDecimal("1.0");

    public MotilityStatus assessStatus(BigDecimal currentFrequency, BigDecimal baseline) {
        if (currentFrequency == null) return MotilityStatus.NORMAL;
        BigDecimal bl = baseline != null ? baseline : DEFAULT_BASELINE;

        BigDecimal abnormalLine = bl.multiply(ABNORMAL_RATIO).min(CLINICAL_FLOOR);
        if (currentFrequency.compareTo(abnormalLine) < 0) {
            return MotilityStatus.ABNORMAL;
        }
        if (currentFrequency.compareTo(bl.multiply(LOW_RATIO)) < 0) {
            return MotilityStatus.LOW;
        }
        return MotilityStatus.NORMAL;
    }

   public String generateAdvice(MotilityStatus status) {
       return switch (status) {
            case ABNORMAL -> "Rumen motility significantly low. Check feed quality and water intake.";
            case LOW -> "Rumen motility below normal. Monitor feeding behavior.";
            case NORMAL -> "Digestive function normal";
       };
   }
}
