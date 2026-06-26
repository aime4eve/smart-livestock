package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.dto.EvaluationReport;
import com.smartlivestock.datagen.application.dto.MetricResult;
import com.smartlivestock.datagen.domain.model.*;
import com.smartlivestock.datagen.domain.port.AnomalyScoreQueryPort;
import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import com.smartlivestock.datagen.domain.port.dto.AnomalyScoreInfo;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;

/**
 * Dual-dimension evaluation: HEALTH (anomaly scores) + FENCE (breach detection).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EvaluationService {

    private final GroundTruthLabelRepository labelRepository;
    private final AnomalyScoreQueryPort anomalyScorePort;
    private final DeviceQueryPort deviceQueryPort;

    public EvaluationReport evaluate(Instant from, Instant to, double scoreThreshold) {
        List<Long> livestockIds = deviceQueryPort.findActiveInstallations().stream()
                .map(ActiveInstallationInfo::livestockId).distinct().toList();

        // Collect all labels in window
        List<GroundTruthLabel> healthLabels = new ArrayList<>();
        List<GroundTruthLabel> fenceLabels = new ArrayList<>();
        for (Long id : livestockIds) {
            for (GroundTruthLabel l : labelRepository.findByLivestockIdAndPeriodOverlap(id, from, to)) {
                if (l.getScenarioType() == ScenarioType.HEALTH && l.getPattern() != AnomalyPattern.NORMAL) {
                    healthLabels.add(l);
                } else if (l.getScenarioType() == ScenarioType.FENCE_BREACH
                        || l.getScenarioType() == ScenarioType.FENCE_APPROACH) {
                    fenceLabels.add(l);
                }
            }
        }

        // HEALTH evaluation: compare labels × anomaly_scores
        List<AnomalyScoreInfo> scores = anomalyScorePort.findByLivestockIdsAndPeriod(livestockIds, from, to);
        HealthMetrics health = evaluateHealth(livestockIds, healthLabels, scores, scoreThreshold);

        // FENCE evaluation: injected breaches vs alerts (simplified — counts injected vs detected)
        FenceMetrics fence = evaluateFence(livestockIds, fenceLabels, from, to);

        return new EvaluationReport(from, to,
                healthLabels.size() + fenceLabels.size(), scores.size(),
                health.precision(), health.recall(), health.f1(), health.perPattern(),
                fence.injectedCount(), fence.metrics());
    }

    private record HealthMetrics(double precision, double recall, double f1, List<MetricResult> perPattern) {}

    private HealthMetrics evaluateHealth(List<Long> livestockIds, List<GroundTruthLabel> labels,
            List<AnomalyScoreInfo> scores, double threshold) {
        if (scores.isEmpty()) {
            return new HealthMetrics(0, 0, 0, List.of());
        }

        Map<Long, Boolean> labeledAbnormal = new HashMap<>();
        for (GroundTruthLabel l : labels) {
            labeledAbnormal.merge(l.getLivestockId(), true, (a, b) -> a || b);
        }
        Map<Long, Boolean> scoredHigh = new HashMap<>();
        for (AnomalyScoreInfo s : scores) {
            if (s.anomalyScore() != null && s.anomalyScore().doubleValue() >= threshold) {
                scoredHigh.merge(s.livestockId(), true, (a, b) -> a || b);
            }
        }

        int tp = 0, fp = 0, fn = 0, tn = 0;
        for (Long id : livestockIds) {
            boolean abnormal = labeledAbnormal.getOrDefault(id, false);
            boolean high = scoredHigh.getOrDefault(id, false);
            if (abnormal && high) tp++;
            else if (!abnormal && high) fp++;
            else if (abnormal && !high) fn++;
            else tn++;
        }

        double precision = (tp + fp) > 0 ? (double) tp / (tp + fp) : 0.0;
        double recall = (tp + fn) > 0 ? (double) tp / (tp + fn) : 0.0;
        double f1 = (precision + recall) > 0 ? 2.0 * precision * recall / (precision + recall) : 0.0;

        List<MetricResult> perPattern = new ArrayList<>();
        for (AnomalyPattern p : AnomalyPattern.values()) {
            if (p == AnomalyPattern.NORMAL) continue;
            long count = labels.stream().filter(l -> l.getPattern() == p).count();
            if (count > 0) {
                perPattern.add(new MetricResult(p, tp, fp, fn, tn, precision, recall, f1));
            }
        }

        return new HealthMetrics(precision, recall, f1, perPattern);
    }

    private record FenceMetrics(int injectedCount, List<MetricResult> metrics) {}

    private FenceMetrics evaluateFence(List<Long> livestockIds, List<GroundTruthLabel> fenceLabels,
            Instant from, Instant to) {
        // Count unique livestock with fence labels (injected)
        long injected = fenceLabels.stream()
                .map(GroundTruthLabel::getLivestockId).distinct().count();

        // Note: actual detection (alerts) would require querying ranch alerts table.
        // For now, report injected count. Full fence evaluation requires AlertQueryPort.
        List<MetricResult> metrics = List.of();
        return new FenceMetrics((int) injected, metrics);
    }
}
