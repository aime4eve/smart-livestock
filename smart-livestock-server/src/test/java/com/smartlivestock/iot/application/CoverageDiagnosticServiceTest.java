package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.CoverageDiagnosticService.Cell;
import com.smartlivestock.iot.application.CoverageDiagnosticService.GatewayPoint;
import com.smartlivestock.iot.application.CoverageDiagnosticService.Suggestion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * F8 advice engine rules (see requirements doc §4.8): advice fires only when
 * the edge share exceeds the threshold AND a dominant direction or a clustered
 * weak area exists; otherwise the honest answer is "coverage is fine".
 */
class CoverageDiagnosticServiceTest {

    private static final GatewayPoint GW = new GatewayPoint("gw183", 28.2465617, 112.8513945);

    @Test
    void healthyCoverage_returnsNone() {
        // edge 2.3% (below 10%) → no advice even with scattered weak cells.
        List<Cell> cells = List.of(
                new Cell("stable", 500, -70, 28.2466, 112.8512),
                new Cell("weak", 30, -96, 28.2480, 112.8530));
        List<Suggestion> out = CoverageDiagnosticService.buildSuggestions(
                2.3, 28.2466, 112.8512, 28.2480, 112.8530, 30, cells, List.of(GW), 30, 1000);
        assertThat(out).hasSize(1);
        assertThat(out.get(0).type()).isEqualTo("NONE");
    }

    @Test
    void clusteredWeakArea_triggersAddGateway() {
        // edge 35% + three adjacent weak cells east of the gateway → ADD_GATEWAY.
        List<Cell> cells = List.of(
                new Cell("stable", 500, -75, 28.2466, 112.8512),
                new Cell("edge", 60, -108, 28.2466, 112.8560),
                new Cell("edge", 55, -110, 28.2466, 112.8572),
                new Cell("edge", 50, -109, 28.2478, 112.8560));
        List<Suggestion> out = CoverageDiagnosticService.buildSuggestions(
                35, 28.2466, 112.8512, 28.2470, 112.8565, 165,
                cells, List.of(GW), 165, 1000);
        assertThat(out).hasSize(1);
        assertThat(out.get(0).type()).isEqualTo("ADD_GATEWAY");
        assertThat(out.get(0).targetLat()).isNotNull();
        assertThat(out.get(0).rssiGainDb()).isGreaterThan(0);
        assertThat(out.get(0).edgePctAfter()).isLessThan(out.get(0).edgePctBefore());
    }

    @Test
    void dominantWeakDirection_triggersMoveAntenna() {
        // Weak frames' centroid sits NE of the all-frame centroid (offset > 150m)
        // without 3 clustered cells → MOVE_ANTENNA with a direction name.
        List<Cell> cells = List.of(
                new Cell("stable", 400, -70, 28.2466, 112.8512),
                new Cell("edge", 200, -105, 28.2520, 112.8560),
                new Cell("edge", 150, -106, 28.2530, 112.8580),
                new Cell("edge", 120, -104, 28.2500, 112.8540));
        List<Suggestion> out = CoverageDiagnosticService.buildSuggestions(
                40, 28.2470, 112.8520, 28.2520, 112.8565, 470,
                cells, List.of(GW), 470, 1000);
        assertThat(out).hasSize(1);
        assertThat(out.get(0).type()).isEqualTo("MOVE_ANTENNA");
        assertThat(out.get(0).direction()).isIn("NE", "E", "N");
    }

    @Test
    void edgeBelowTrigger_withNoDirection_isNone() {
        // Weak centroid coincides with the all-frame centroid and edge 8% → NONE.
        List<Cell> cells = List.of(
                new Cell("stable", 900, -80, 28.2466, 112.8512),
                new Cell("edge", 80, -102, 28.2466, 112.8512));
        List<Suggestion> out = CoverageDiagnosticService.buildSuggestions(
                8, 28.2466, 112.8512, 28.2466, 112.8512, 80, cells, List.of(GW), 80, 980);
        assertThat(out.get(0).type()).isEqualTo("NONE");
    }

    @Test
    void noGatewaysRegistered_isNone() {
        List<Cell> cells = List.of(new Cell("edge", 500, -110, 28.2466, 112.8560));
        List<Suggestion> out = CoverageDiagnosticService.buildSuggestions(
                40, 28.2466, 112.8512, 28.2466, 112.8560, 500, cells, List.of(), 500, 1000);
        assertThat(out.get(0).type()).isEqualTo("NONE");
    }
}
