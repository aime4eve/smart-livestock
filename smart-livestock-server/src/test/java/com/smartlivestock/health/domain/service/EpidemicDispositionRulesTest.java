package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.EpidemicDispositionAction;
import com.smartlivestock.health.domain.model.EpidemicDispositionTier;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class EpidemicDispositionRulesTest {

    @Test
    void directRecentHighRiskWithHealthSignalIsolatesWithinTwoHours() {
        var result = EpidemicDispositionRules.classify(true, 3, 82, 1, true, 70, 80, 40);
        assertThat(result.tier()).isEqualTo(EpidemicDispositionTier.CRITICAL);
        assertThat(result.action()).isEqualTo(EpidemicDispositionAction.ISOLATE_NOTIFY_VET);
        assertThat(result.dueHours()).isEqualTo(2);
    }

    @Test
    void directRecentVeryHighRiskWithoutHealthSignalRequiresImmediateCheck() {
        var result = EpidemicDispositionRules.classify(true, 6, 82, 1, false, 70, 80, 40);
        assertThat(result.tier()).isEqualTo(EpidemicDispositionTier.CRITICAL);
        assertThat(result.action()).isEqualTo(EpidemicDispositionAction.IMMEDIATE_VET_CHECK);
        assertThat(result.dueHours()).isEqualTo(4);
    }

    @Test
    void directMediumRiskOrIndirectHighRiskIsObserved() {
        var direct = EpidemicDispositionRules.classify(true, 30, 58, 1, false, 70, 80, 40);
        var indirect = EpidemicDispositionRules.classify(false, Integer.MAX_VALUE, 75, 2, false, 70, 80, 40);
        assertThat(direct.tier()).isEqualTo(EpidemicDispositionTier.OBSERVATION);
        assertThat(indirect.tier()).isEqualTo(EpidemicDispositionTier.OBSERVATION);
        assertThat(direct.dueHours()).isEqualTo(24);
    }

    @Test
    void olderMediumRiskIsTracked() {
        var result = EpidemicDispositionRules.classify(true, 60, 58, 1, false, 70, 80, 40);
        assertThat(result.tier()).isEqualTo(EpidemicDispositionTier.TRACKING);
        assertThat(result.action()).isEqualTo(EpidemicDispositionAction.CONTINUE_TRACING);
        assertThat(result.dueHours()).isEqualTo(72);
    }

    @Test
    void olderOrLowerRiskIsArchived() {
        var result = EpidemicDispositionRules.classify(true, 60, 28, 1, false, 70, 80, 40);
        assertThat(result.tier()).isEqualTo(EpidemicDispositionTier.ARCHIVE);
        assertThat(result.action()).isEqualTo(EpidemicDispositionAction.ARCHIVE_ONLY);
        assertThat(result.dueHours()).isNull();
    }

    @Test
    void remoteLowRiskIsArchived() {
        var result = EpidemicDispositionRules.classify(false, Integer.MAX_VALUE, 28, 3, false, 70, 80, 40);
        assertThat(result.tier()).isEqualTo(EpidemicDispositionTier.ARCHIVE);
        assertThat(result.action()).isEqualTo(EpidemicDispositionAction.ARCHIVE_ONLY);
        assertThat(result.dueHours()).isNull();
    }
}
