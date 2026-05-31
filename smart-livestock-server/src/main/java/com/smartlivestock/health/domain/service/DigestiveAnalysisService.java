package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.RumenMotilityLog;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * Analyzes rumen motility logs to detect digestive issues.
 * Rules:
 *   frequency ≥ baseline × 0.7              → NORMAL
 *   baseline × 0.5 ≤ frequency < baseline × 0.7 → LOW
 *   frequency < baseline × 0.5              → ABNORMAL
 */
@Service
public class DigestiveAnalysisService {

    private static final BigDecimal LOW_RATIO = new BigDecimal("0.7");
    private static final BigDecimal ABNORMAL_RATIO = new BigDecimal("0.5");
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("3.0");

    public MotilityStatus assessStatus(BigDecimal currentFrequency, BigDecimal baseline) {
        if (currentFrequency == null) return MotilityStatus.NORMAL;
        BigDecimal bl = baseline != null ? baseline : DEFAULT_BASELINE;

        if (currentFrequency.compareTo(bl.multiply(ABNORMAL_RATIO)) < 0) {
            return MotilityStatus.ABNORMAL;
        }
        if (currentFrequency.compareTo(bl.multiply(LOW_RATIO)) < 0) {
            return MotilityStatus.LOW;
        }
        return MotilityStatus.NORMAL;
    }

    public String generateAdvice(MotilityStatus status) {
        return switch (status) {
            case ABNORMAL -> "蠕动频率显著偏低，建议检查饲料质量和饮水量";
            case LOW -> "蠕动频率偏低，建议观察进食情况";
            case NORMAL -> "消化功能正常";
        };
    }
}
