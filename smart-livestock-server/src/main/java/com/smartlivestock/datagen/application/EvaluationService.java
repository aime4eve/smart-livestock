package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.dto.EvaluationReport;
import com.smartlivestock.datagen.application.dto.MetricResult;
import com.smartlivestock.datagen.domain.model.AnomalyPattern;
import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.LabelSource;
import com.smartlivestock.datagen.domain.port.AnomalyScoreQueryPort;
import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import com.smartlivestock.datagen.domain.port.dto.AnomalyScoreInfo;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;

/**
 * Evaluates AI anomaly detection against ground-truth labels.
 *
 * Compares anomaly_scores (from ai-platform via Health ACL) with ground_truth_labels
 * (from datagen SYNTHETIC injection), computing precision/recall/F1 per pattern + overall.
 *
 * Note: scores may be empty if anomaly_scores table doesn't exist yet (Phase B deliverable 2).
 * In that case, AnomalyScoreQueryPort returns empty list and evaluation reports zeros.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EvaluationService {

    private final GroundTruthLabelService labelService;
    private final AnomalyScoreQueryPort anomalyScorePort;
    private final DeviceQueryPort deviceQueryPort;

    public EvaluationReport evaluate(Instant from, Instant to, double scoreThreshold) {
        List<Long> livestockIds = deviceQueryPort.findActiveInstallations().stream()
                .map(ActiveInstallationInfo::livestockId).distinct().toList();

        // Collect labels and scores
        List<GroundTruthLabel> labels = new ArrayList<>();
        for (Long id : livestockIds) {
            labels.addAll(labelService.findByLivestockAndPeriod(id, from, to));
        }
        List<AnomalyScoreInfo> scores = anomalyScorePort.findByLivestockIdsAndPeriod(livestockIds, from, to);

        if (scores.isEmpty()) {
            return new EvaluationReport(from, to, labels.size(), 0,
                    0, 0, 0, List.of());
        }

        // Build per-livestock label maps: has anomaly label (non-NORMAL) overlapping [from,to]
        Map<Long, Boolean> labeledAbnormal = new HashMap<>();
        for (GroundTruthLabel label : labels) {
            if (label.getPattern() != AnomalyPattern.NORMAL) {
                labeledAbnormal.merge(label.getLivestockId(), true, (a, b) -> a || b);
            }
        }

        // Build per-livestock score maps: has high score
        Map<Long, Boolean> scoredHigh = new HashMap<>();
        for (AnomalyScoreInfo score : scores) {
            if (score.anomalyScore() != null
                    && score.anomalyScore().doubleValue() >= scoreThreshold) {
                scoredHigh.merge(score.livestockId(), true, (a, b) -> a || b);
            }
        }

        // Confusion matrix (overall)
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

        // Per-pattern metrics (simplified: count labels per pattern)
        List<MetricResult> perPattern = new ArrayList<>();
        for (AnomalyPattern pattern : AnomalyPattern.values()) {
            if (pattern == AnomalyPattern.NORMAL) continue;
            long patternLabels = labels.stream()
                    .filter(l -> l.getPattern() == pattern).count();
            if (patternLabels > 0) {
                perPattern.add(new MetricResult(pattern, tp, fp, fn, tn, precision, recall, f1));
            }
        }

        return new EvaluationReport(from, to, labels.size(), scores.size(),
                precision, recall, f1, perPattern);
    }
}
