package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.dto.EvaluationReport;
import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.port.AlertQueryPort;
import com.smartlivestock.datagen.domain.port.AnomalyScoreQueryPort;
import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import com.smartlivestock.datagen.domain.port.dto.AnomalyScoreInfo;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import com.smartlivestock.iot.domain.model.DeviceType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the anomaly-label evaluation's NIX-286 verdict
 * compatibility: REJECTED / SUPERSEDED health labels are excluded from the
 * abnormal-positive pool (label-level filter), while CONFIRMED rows and
 * verdict-less rows (null = legacy SYNTHETIC / BREEDING_DERIVED) still
 * contribute. Pure construction with mocked ports and repository.
 */
class EvaluationServiceTest {

    private static final Instant FROM = Instant.parse("2026-11-01T00:00:00Z");
    private static final Instant TO = Instant.parse("2026-11-10T00:00:00Z");
    private static final Long LIVESTOCK_ID = 5L;

    private GroundTruthLabelRepository labelRepository;
    private AnomalyScoreQueryPort anomalyScorePort;
    private EvaluationService service;

    @BeforeEach
    void setUp() {
        labelRepository = mock(GroundTruthLabelRepository.class);
        anomalyScorePort = mock(AnomalyScoreQueryPort.class);
        DeviceQueryPort deviceQueryPort = mock(DeviceQueryPort.class);
        when(deviceQueryPort.findActiveInstallations()).thenReturn(List.of(
                new ActiveInstallationInfo(1L, LIVESTOCK_ID, DeviceType.EAR_TAG)));
        service = new EvaluationService(labelRepository, anomalyScorePort,
                mock(AlertQueryPort.class), deviceQueryPort);
    }

    /** One ESTRUS (HEALTH, not simulation-only) label with the given verdict. */
    private static GroundTruthLabel label(String verdict) {
        GroundTruthLabel label = new GroundTruthLabel();
        label.setLivestockId(LIVESTOCK_ID);
        label.setType(ScenarioType.ESTRUS);
        label.setPeriodStart(FROM);
        label.setPeriodEnd(TO);
        label.setVerdict(verdict);
        return label;
    }

    private AnomalyScoreInfo highScore() {
        return new AnomalyScoreInfo(LIVESTOCK_ID, new BigDecimal("0.9"), "ESTRUS", FROM);
    }

    /**
     * Mixed verdicts: only CONFIRMED and verdict-less rows count as labels —
     * REJECTED (human-denied candidate false positive) and SUPERSEDED (spent
     * flipped row) are ignored, and the surviving rows still mark the
     * livestock abnormal (recall 1.0 with no high scores → one false negative).
     */
    @Test
    void onlyConfirmedAndVerdictlessLabelsSurviveTheVerdictFilter() {
        when(labelRepository.findByLivestockIdAndPeriodOverlap(LIVESTOCK_ID, FROM, TO))
                .thenReturn(List.of(
                        label(GroundTruthLabel.VERDICT_CONFIRMED),
                        label(null),
                        label(GroundTruthLabel.VERDICT_REJECTED),
                        label(GroundTruthLabel.VERDICT_SUPERSEDED)));

        EvaluationReport report = service.evaluate(FROM, TO, 0.7);

        assertThat(report.totalLabels()).isEqualTo(2);
        assertThat(report.healthPerPattern()).hasSize(1);
        assertThat(report.healthPerPattern().get(0).type()).isEqualTo(ScenarioType.ESTRUS);
        // CONFIRMED + null rows marked the livestock abnormal (fn=1, the
        // per-pattern rows carry the global confusion counts); no anomaly
        // scores scored high → nothing detected, recall 0.0.
        assertThat(report.healthPerPattern().get(0).falseNegative()).isEqualTo(1);
        assertThat(report.overallRecall()).isZero();
    }

    /**
     * REJECTED / SUPERSEDED-only labels never mark the livestock abnormal: a
     * high anomaly score must land as a false positive, not a true positive.
     */
    @Test
    void rejectedAndSupersededLabelsDoNotMarkLivestockAbnormal() {
        when(labelRepository.findByLivestockIdAndPeriodOverlap(LIVESTOCK_ID, FROM, TO))
                .thenReturn(List.of(
                        label(GroundTruthLabel.VERDICT_REJECTED),
                        label(GroundTruthLabel.VERDICT_SUPERSEDED)));
        when(anomalyScorePort.findByLivestockIdsAndPeriod(List.of(LIVESTOCK_ID), FROM, TO))
                .thenReturn(List.of(highScore()));

        EvaluationReport report = service.evaluate(FROM, TO, 0.7);

        assertThat(report.totalLabels()).isZero();
        assertThat(report.healthPerPattern()).isEmpty();
        // abnormal=false, high=true → fp; precision/recall/f1 all zero.
        // (Without the filter the two rows would mark abnormal=true → tp.)
        assertThat(report.overallPrecision()).isZero();
        assertThat(report.overallRecall()).isZero();
        assertThat(report.overallF1()).isZero();
    }

    /** Positive control: a CONFIRMED row plus a high score is a true positive. */
    @Test
    void confirmedLabelWithHighScoreCountsAsTruePositive() {
        when(labelRepository.findByLivestockIdAndPeriodOverlap(LIVESTOCK_ID, FROM, TO))
                .thenReturn(List.of(label(GroundTruthLabel.VERDICT_CONFIRMED)));
        when(anomalyScorePort.findByLivestockIdsAndPeriod(List.of(LIVESTOCK_ID), FROM, TO))
                .thenReturn(List.of(highScore()));

        EvaluationReport report = service.evaluate(FROM, TO, 0.7);

        assertThat(report.totalLabels()).isEqualTo(1);
        assertThat(report.overallPrecision()).isEqualTo(1.0);
        assertThat(report.overallRecall()).isEqualTo(1.0);
    }
}
