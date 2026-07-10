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

        List<GroundTruthLabel> healthLabels = new ArrayList<>();
        List<GroundTruthLabel> breachLabels = new ArrayList<>();
        List<GroundTruthLabel> approachLabels = new ArrayList<>();
        for (Long id : livestockIds) {
            for (GroundTruthLabel l : labelRepository.findByLivestockIdAndPeriodOverlap(id, from, to)) {
                ScenarioType t = l.getType();
                if (t.getCategory() == ScenarioType.Category.HEALTH) healthLabels.add(l);
                else if (t == ScenarioType.FENCE_BREACH) breachLabels.add(l);
                else if (t == ScenarioType.FENCE_APPROACH) approachLabels.add(l);
            }
        }

        List<AnomalyScoreInfo> scores = anomalyScorePort.findByLivestockIdsAndPeriod(livestockIds, from, to);
        // Health evaluation
        Map<Long, Boolean> labeledAbnormal = new HashMap<>();
        for (GroundTruthLabel l : healthLabels) labeledAbnormal.merge(l.getLivestockId(), true, (a, b) -> a || b);
        Map<Long, Boolean> scoredHigh = new HashMap<>();
        for (AnomalyScoreInfo s : scores) {
            if (s.anomalyScore() != null && s.anomalyScore().doubleValue() >= scoreThreshold)
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
        List<MetricResult> healthPerPattern = new ArrayList<>();
        for (ScenarioType t : ScenarioType.values()) {
            if (t.getCategory() != ScenarioType.Category.HEALTH) continue;
            long count = healthLabels.stream().filter(l -> l.getType() == t).count();
            if (count > 0) healthPerPattern.add(new MetricResult(t, tp, fp, fn, tn, precision, recall, f1));
        }

        // Fence evaluation
        List<AlertInfo> fenceAlerts = alertPort.findFenceAlertsByLivestockIds(livestockIds, from, to);
        Set<Long> injectedBreach = new HashSet<>();
        for (GroundTruthLabel l : breachLabels) injectedBreach.add(l.getLivestockId());
        Set<Long> injectedApproach = new HashSet<>();
        for (GroundTruthLabel l : approachLabels) injectedApproach.add(l.getLivestockId());
        Set<Long> detectedBreach = new HashSet<>();
        Set<Long> detectedApproach = new HashSet<>();
        for (AlertInfo a : fenceAlerts) {
            if ("FENCE_BREACH".equals(a.type())) detectedBreach.add(a.livestockId());
            else if ("FENCE_APPROACH".equals(a.type())) detectedApproach.add(a.livestockId());
        }
        long breachHit = injectedBreach.stream().filter(detectedBreach::contains).count();
        long approachHit = injectedApproach.stream().filter(detectedApproach::contains).count();

        return new EvaluationReport(from, to,
                healthLabels.size() + breachLabels.size() + approachLabels.size(), scores.size(),
                precision, recall, f1, healthPerPattern,
                injectedBreach.size(), injectedApproach.size(),
                detectedBreach.size(), detectedApproach.size());
    }
}
