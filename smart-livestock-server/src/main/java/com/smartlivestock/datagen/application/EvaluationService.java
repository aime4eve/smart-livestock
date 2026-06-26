package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.dto.EvaluationReport;
import com.smartlivestock.datagen.application.dto.MetricResult;
import com.smartlivestock.datagen.domain.model.*;
import com.smartlivestock.datagen.domain.port.AlertQueryPort;
import com.smartlivestock.datagen.domain.port.AnomalyScoreQueryPort;
import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import com.smartlivestock.datagen.domain.port.dto.AlertInfo;
import com.smartlivestock.datagen.domain.port.dto.AnomalyScoreInfo;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;

/**
 * Dual-dimension evaluation:
 * - HEALTH: ground_truth_labels × anomaly_scores → precision/recall/F1 per pattern
 * - FENCE: ground_truth_labels × fence alerts → breach/approach recall
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EvaluationService {

    private final GroundTruthLabelRepository labelRepository;
    private final AnomalyScoreQueryPort anomalyScorePort;
    private final AlertQueryPort alertPort;
    private final DeviceQueryPort deviceQueryPort;

    public EvaluationReport evaluate(Instant from, Instant to, double scoreThreshold) {
        List<Long> livestockIds = deviceQueryPort.findActiveInstallations().stream()
                .map(ActiveInstallationInfo::livestockId).distinct().toList();

        // Collect labels by dimension
        List<GroundTruthLabel> healthLabels = new ArrayList<>();
        List<GroundTruthLabel> breachLabels = new ArrayList<>();
        List<GroundTruthLabel> approachLabels = new ArrayList<>();
        for (Long id : livestockIds) {
            for (GroundTruthLabel l : labelRepository.findByLivestockIdAndPeriodOverlap(id, from, to)) {
                if (l.getScenarioType() == ScenarioType.HEALTH && l.getPattern() != AnomalyPattern.NORMAL) {
                    healthLabels.add(l);
                } else if (l.getScenarioType() == ScenarioType.FENCE_BREACH) {
                    breachLabels.add(l);
                } else if (l.getScenarioType() == ScenarioType.FENCE_APPROACH) {
                    approachLabels.add(l);
                }
            }
        }

        // HEALTH evaluation
        List<AnomalyScoreInfo> scores = anomalyScorePort.findByLivestockIdsAndPeriod(livestockIds, from, to);
        HealthMetrics health = evaluateHealth(livestockIds, healthLabels, scores, scoreThreshold);

        // FENCE evaluation: injected breaches × fence alerts
        List<AlertInfo> fenceAlerts = alertPort.findFenceAlertsByLivestockIds(livestockIds, from, to);
        FenceMetrics fence = evaluateFence(livestockIds, breachLabels, approachLabels, fenceAlerts);

        return new EvaluationReport(from, to,
                healthLabels.size() + breachLabels.size() + approachLabels.size(), scores.size(),
                health.precision(), health.recall(), health.f1(), health.perPattern(),
                fence.injectedBreachCount(), fence.injectedApproachCount(),
                fence.detectedBreachCount(), fence.detectedApproachCount(), fence.metrics());
    }

    private record HealthMetrics(double precision, double recall, double f1, List<MetricResult> perPattern) {}

    private HealthMetrics evaluateHealth(List<Long> livestockIds, List<GroundTruthLabel> labels,
            List<AnomalyScoreInfo> scores, double threshold) {
        if (scores.isEmpty()) return new HealthMetrics(0, 0, 0, List.of());

        Map<Long, Boolean> labeledAbnormal = new HashMap<>();
        for (GroundTruthLabel l : labels) labeledAbnormal.merge(l.getLivestockId(), true, (a, b) -> a || b);
        Map<Long, Boolean> scoredHigh = new HashMap<>();
        for (AnomalyScoreInfo s : scores) {
            if (s.anomalyScore() != null && s.anomalyScore().doubleValue() >= threshold)
                scoredHigh.merge(s.livestockId(), true, (a, b) -> a || b);
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
            if (count > 0) perPattern.add(new MetricResult(p, tp, fp, fn, tn, precision, recall, f1));
        }
        return new HealthMetrics(precision, recall, f1, perPattern);
    }

    private record FenceMetrics(int injectedBreachCount, int injectedApproachCount,
            int detectedBreachCount, int detectedApproachCount, List<MetricResult> metrics) {}

    private FenceMetrics evaluateFence(List<Long> livestockIds,
            List<GroundTruthLabel> breachLabels, List<GroundTruthLabel> approachLabels,
            List<AlertInfo> alerts) {
        // Livestock injected with FENCE_BREACH / FENCE_APPROACH
        Set<Long> injectedBreach = new HashSet<>();
        for (GroundTruthLabel l : breachLabels) injectedBreach.add(l.getLivestockId());
        Set<Long> injectedApproach = new HashSet<>();
        for (GroundTruthLabel l : approachLabels) injectedApproach.add(l.getLivestockId());

        // Livestock that received FENCE_BREACH / FENCE_APPROACH alerts
        Set<Long> detectedBreach = new HashSet<>();
        Set<Long> detectedApproach = new HashSet<>();
        for (AlertInfo a : alerts) {
            if ("FENCE_BREACH".equals(a.type())) detectedBreach.add(a.livestockId());
            else if ("FENCE_APPROACH".equals(a.type())) detectedApproach.add(a.livestockId());
        }

        // Recall: of injected, how many were detected?
        long breachHit = injectedBreach.stream().filter(detectedBreach::contains).count();
        long approachHit = injectedApproach.stream().filter(detectedApproach::contains).count();
        double breachRecall = injectedBreach.isEmpty() ? 0.0 : (double) breachHit / injectedBreach.size();
        double approachRecall = injectedApproach.isEmpty() ? 0.0 : (double) approachHit / injectedApproach.size();

        List<MetricResult> metrics = List.of(
                new MetricResult(AnomalyPattern.NORMAL, // reuse as placeholder for FENCE_BREACH
                        (int) breachHit, 0,
                        (int) (injectedBreach.size() - breachHit), 0,
                        breachRecall, breachRecall, breachRecall));

        return new FenceMetrics(injectedBreach.size(), injectedApproach.size(),
                detectedBreach.size(), detectedApproach.size(), metrics);
    }
}
