package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

/**
 * Multi-dimensional estrus scoring (0-100).
 * score = step_score × 0.4 + temp_score × 0.3 + distance_score × 0.3
 */
@Service
public class EstrusAnalysisService {

    public int calculateScore(int stepIncreasePercent, BigDecimal tempDelta, BigDecimal distanceDelta) {
        double stepScore = scoreStepIncrease(stepIncreasePercent);
        double tempScore = scoreTempDelta(tempDelta);
        double distScore = scoreDistanceDelta(distanceDelta);
       double raw = stepScore * 0.4 + tempScore * 0.3 + distScore * 0.3;
       return (int) Math.round(Math.max(0, Math.min(100, raw)));
    }

   public String generateAdvice(int score) {
       if (score >= 70) {
            return "High estrus score. Breeding recommended within 12 hours.";
       } else if (score >= 50) {
            return "Moderately high estrus score. Continue monitoring and prepare for breeding.";
       }
        return "Not in estrus";
   }

    private double scoreStepIncrease(int increasePercent) {
        if (increasePercent > 300) return 85 + Math.min((increasePercent - 300) / 100.0 * 15, 15);
        if (increasePercent > 150) return 60 + (increasePercent - 150) / 150.0 * 25;
        if (increasePercent > 50) return 20 + (increasePercent - 50) / 100.0 * 40;
        return increasePercent / 50.0 * 20;
    }

    private double scoreTempDelta(BigDecimal delta) {
        if (delta == null) return 0;
        double d = delta.doubleValue();
        if (d > 0.5) return 40 + Math.min((d - 0.5) / 0.5 * 20, 20);
        if (d > 0.2) return 10 + (d - 0.2) / 0.3 * 30;
        return d / 0.2 * 10;
    }

    private double scoreDistanceDelta(BigDecimal delta) {
        if (delta == null) return 0;
        double d = delta.doubleValue();
        if (d > 2000) return 50 + Math.min((d - 2000) / 1000.0 * 20, 20);
        if (d > 500) return 15 + (d - 500) / 1500.0 * 35;
        return d / 500.0 * 15;
    }
}
