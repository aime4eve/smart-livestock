package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.service.PhysiologyQueryService.PairedWindow;
import com.smartlivestock.health.application.service.PhysiologyQueryService.TimedEvent;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Pure unit tests for the manual ILLNESS/RECOVERY stack pairing
 * (NIX-256 Task 1a). No Spring context, no Docker — runs anywhere.
 */
class PhysiologyPairingTest {

    private static final Instant T1 = Instant.parse("2026-01-01T00:00:00Z");
    private static final Instant T2 = Instant.parse("2026-01-02T00:00:00Z");
    private static final Instant T3 = Instant.parse("2026-01-03T00:00:00Z");
    private static final Instant T4 = Instant.parse("2026-01-04T00:00:00Z");

    private static TimedEvent illness(Instant at) {
        return new TimedEvent(PhysiologyEventType.ILLNESS, at);
    }

    private static TimedEvent recovery(Instant at) {
        return new TimedEvent(PhysiologyEventType.RECOVERY, at);
    }

    @Test
    void singleIllnessWithoutRecoveryStaysOpen() {
        List<PairedWindow> windows = PhysiologyQueryService.pairIllnessRecovery(List.of(illness(T1)));
        assertThat(windows).containsExactly(new PairedWindow(T1, null));
    }

    @Test
    void illnessThenRecoveryCloses() {
        List<PairedWindow> windows = PhysiologyQueryService.pairIllnessRecovery(
                List.of(illness(T1), recovery(T2)));
        assertThat(windows).containsExactly(new PairedWindow(T1, T2));
    }

    @Test
    void twoNestedPairsCloseInnerFirst() {
        // I1, I2, R, R → inner pair [T2,T3] closes first, outer [T1,T4] last.
        List<PairedWindow> windows = PhysiologyQueryService.pairIllnessRecovery(
                List.of(illness(T1), illness(T2), recovery(T3), recovery(T4)));
        assertThat(windows).containsExactly(
                new PairedWindow(T1, T4),
                new PairedWindow(T2, T3));
    }

    @Test
    void recoveryBeforeIllnessIsIgnoredAndInputOrderDoesNotMatter() {
        // Entered out of order (recovery first); after chronological sort the
        // recovery has no open illness to close, and the illness stays open.
        List<PairedWindow> windows = PhysiologyQueryService.pairIllnessRecovery(
                List.of(recovery(T1), illness(T2)));
        assertThat(windows).containsExactly(new PairedWindow(T2, null));
    }

    @Test
    void surplusRecoveryDoesNotFormAWindow() {
        List<PairedWindow> windows = PhysiologyQueryService.pairIllnessRecovery(
                List.of(illness(T1), recovery(T2), recovery(T3)));
        assertThat(windows).containsExactly(new PairedWindow(T1, T2));
    }

    @Test
    void nonIllnessLaneEventsAreIgnored() {
        List<PairedWindow> windows = PhysiologyQueryService.pairIllnessRecovery(
                List.of(new TimedEvent(PhysiologyEventType.CALVING, T1),
                        illness(T2),
                        new TimedEvent(PhysiologyEventType.BREEDING, T3),
                        recovery(T4)));
        assertThat(windows).containsExactly(new PairedWindow(T2, T4));
    }

    @Test
    void emptyInputYieldsNoWindows() {
        assertThat(PhysiologyQueryService.pairIllnessRecovery(List.of())).isEmpty();
    }
}
