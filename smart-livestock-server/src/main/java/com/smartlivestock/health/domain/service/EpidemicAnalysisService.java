package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/**
 * Epidemic risk analysis based on herd-level health snapshots.
 */
@Service
public class EpidemicAnalysisService {

    public HerdMetrics calculateHerdMetrics(List<HealthSnapshot> snapshots) {
        if (snapshots == null || snapshots.isEmpty()) {
            return new HerdMetrics(BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0, 0);
        }

        int total = snapshots.size();
        int abnormalCount = 0;
        BigDecimal tempSum = BigDecimal.ZERO;
        BigDecimal activitySum = BigDecimal.ZERO;
        int tempCount = 0;

        for (HealthSnapshot s : snapshots) {
            boolean abnormal = false;
            if (s.getTempStatus() != null && s.getTempStatus().name().equals("FEVER")
                    || s.getTempStatus() != null && s.getTempStatus().name().equals("CRITICAL")) {
                abnormal = true;
            }
            if (s.getMotilityStatus() != null && s.getMotilityStatus().name().equals("ABNORMAL")) {
                abnormal = true;
            }
            if (abnormal) abnormalCount++;

            if (s.getCurrentTemp() != null) {
                tempSum = tempSum.add(s.getCurrentTemp());
                tempCount++;
            }
        }

        BigDecimal avgTemp = tempCount > 0
                ? tempSum.divide(BigDecimal.valueOf(tempCount), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;
        BigDecimal abnormalRate = BigDecimal.valueOf(abnormalCount)
                .divide(BigDecimal.valueOf(total), 4, RoundingMode.HALF_UP);

        return new HerdMetrics(avgTemp, BigDecimal.ZERO, abnormalRate, total, abnormalCount);
    }

    public String assessRiskLevel(BigDecimal abnormalRate) {
        if (abnormalRate == null) return "正常";
        double rate = abnormalRate.doubleValue();
        if (rate > 0.15) return "警戒";
        if (rate > 0.05) return "关注";
        return "正常";
    }

    public record HerdMetrics(
            BigDecimal avgTemperature,
            BigDecimal avgActivity,
            BigDecimal abnormalRate,
            int totalLivestock,
            int abnormalCount
    ) {}
}
