package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.CoverageCellRow;
import com.smartlivestock.iot.domain.model.CoverageTierTotals;
import com.smartlivestock.iot.domain.model.GatewayRegistry;
import com.smartlivestock.iot.domain.model.WeakCentroidRow;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.GatewayRegistryRepository;
import com.smartlivestock.iot.domain.service.TrackLineCalculator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * F8 coverage diagnostics and gateway relocation advice (NIX-219).
 * Three stages over a sliding window of real frames: global tier percentages,
 * 100m-grid heat cells, then rule-based advice — direction test (weak centroid
 * vs all-frame centroid), cluster test (adjacent weak cells), and a
 * log-distance what-if for the expected improvement. When no trigger fires the
 * honest output is "coverage is fine, no change needed" — never noise advice.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CoverageDiagnosticService {

    static final int WINDOW_DAYS = 30;
    static final int MIN_CELL_FRAMES = 15;
    static final double DIRECTION_OFFSET_MIN_M = 150.0;
    static final double EDGE_TRIGGER_PCT = 10.0;
    static final int CLUSTER_MIN_CELLS = 3;
    static final double CLUSTER_NEIGHBOUR_M = 250.0;

    private final GatewayRegistryService gatewayRegistryService;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final GatewayRegistryRepository gatewayRegistryRepository;

    @Value("${smartlivestock.coverage.min-frames:500}")
    private long minFrames;

    @Value("${smartlivestock.coverage.log-n:4.2}")
    private double logN;

    public record Cell(String tier, long frames, double avgRssi,
                       double lat, double lng) {
    }

    public record Suggestion(
            String type, // MOVE_ANTENNA / ADD_GATEWAY / NONE
            String direction, // eight-wind name, nullable
            Double targetLat,
            Double targetLng,
            Double rssiGainDb,
            Double edgePctBefore,
            Double edgePctAfter) {
    }

    public record GatewayPoint(String gatewayId, double lat, double lng) {
    }

    public record CoverageDiagnostic(
            String status, // OK / ACCUMULATING
            int daysCovered,
            long totalFrames,
            double stablePct,
            double weakPct,
            double edgePct,
            List<Cell> cells,
            List<Suggestion> suggestions,
            List<GatewayPoint> gateways) {
    }

    public CoverageDiagnostic diagnose(Long farmId) {
        List<Long> deviceIds = gatewayRegistryService.farmDeviceIds(farmId);
        Instant since = Instant.now().minus(Duration.ofDays(WINDOW_DAYS));

        CoverageTierTotals totals = deviceIds.isEmpty()
                ? new CoverageTierTotals(0, 0, 0, 0, null, null, null)
                : deviceTelemetryLogRepository.coverageTierTotals(deviceIds, since);

        int daysCovered = 0;
        if (totals.earliestFrame() != null) {
            daysCovered = (int) Math.min(WINDOW_DAYS,
                    Duration.between(totals.earliestFrame(), Instant.now()).toDays() + 1);
        }
        if (totals.totalFrames() < minFrames) {
            return new CoverageDiagnostic("ACCUMULATING", daysCovered,
                    totals.totalFrames(), 0, 0, 0, List.of(), List.of(), List.of());
        }

        List<CoverageCellRow> cellRows =
                deviceTelemetryLogRepository.coverageCellRows(deviceIds, since, MIN_CELL_FRAMES);
        List<Cell> cells = cellRows.stream()
                .map(c -> new Cell(tierOf(c.avgRssi()), c.frames(), c.avgRssi(),
                        c.centroidLat(), c.centroidLng()))
                .toList();

        WeakCentroidRow weak = deviceIds.isEmpty()
                ? new WeakCentroidRow(null, null, 0)
                : deviceTelemetryLogRepository.weakCentroid(deviceIds, since);

        double total = totals.totalFrames();
        double stablePct = 100.0 * totals.stableFrames() / total;
        double weakPct = 100.0 * totals.weakFrames() / total;
        double edgePct = 100.0 * totals.edgeFrames() / total;

        List<GatewayPoint> gateways = gatewayRegistryRepository.findAll().stream()
                .map(g -> new GatewayPoint(g.getGatewayId(),
                        g.getLatitude().doubleValue(), g.getLongitude().doubleValue()))
                .toList();

        List<Suggestion> suggestions = buildSuggestions(
                edgePct,
                totals.centroidLat(), totals.centroidLng(),
                weak.centroidLat(), weak.centroidLng(), weak.frames(),
                cells, gateways, totals.weakFrames(), totals.totalFrames());

        return new CoverageDiagnostic("OK", daysCovered, totals.totalFrames(),
                round1(stablePct), round1(weakPct), round1(edgePct),
                cells, suggestions, gateways);
    }

    /**
     * Pure advice engine (unit-tested). Triggers only when edge share exceeds the
     * threshold AND (a dominant weak direction OR a clustered weak area) exists.
     */
    static List<Suggestion> buildSuggestions(
            double edgePct,
            Double allLat, Double allLng,
            Double weakLat, Double weakLng, long weakFrames,
            List<Cell> cells, List<GatewayPoint> gateways,
            long totalWeakFrames, long totalFrames) {

        List<Suggestion> out = new ArrayList<>();
        if (edgePct <= EDGE_TRIGGER_PCT || weakLat == null || allLat == null
                || cells.isEmpty() || gateways.isEmpty() || totalFrames == 0) {
            out.add(new Suggestion("NONE", null, null, null, null, edgePct, null));
            return out;
        }

        double offsetM = TrackLineCalculator.haversineMeters(allLat, allLng, weakLat, weakLng);
        boolean directionConcentrated = offsetM >= DIRECTION_OFFSET_MIN_M;
        List<CoverageCellRow> weakCells = cells.stream()
                .filter(c -> c.avgRssi() < -95)
                .map(c -> new CoverageCellRow(0, 0, c.frames(), c.avgRssi(), c.lat(), c.lng()))
                .toList();
        boolean clustered = hasCluster(weakCells, gateways);

        double avgWeak = weakCells.stream().mapToDouble(CoverageCellRow::avgRssi).average().orElse(Double.NaN);
        double avgAll = cells.stream().mapToDouble(Cell::avgRssi)
                .average().orElse(Double.NaN);
        double gainDb = Double.isNaN(avgWeak) || Double.isNaN(avgAll)
                ? 0 : Math.max(0, avgAll - avgWeak);
        double edgeAfter = Math.max(0, edgePct - gainDb / 2.0);

        if (clustered && weakFrames > 0) {
            double[] centroid = weakCellsCentroid(weakCells);
            double nearest = nearestGatewayDistanceM(centroid[0], centroid[1], gateways);
            double shrink = Math.pow(10, -gainDb / (10 * 4.2));
            out.add(new Suggestion("ADD_GATEWAY", null,
                    round5(centroid[0]), round5(centroid[1]),
                    round1(gainDb), round1(edgePct), round1(edgeAfter)));
        } else if (directionConcentrated) {
            String dir = bearingName(allLat, allLng, weakLat, weakLng);
            out.add(new Suggestion("MOVE_ANTENNA", dir, null, null,
                    round1(gainDb), round1(edgePct), round1(edgeAfter)));
        } else {
            out.add(new Suggestion("NONE", null, null, null, null, edgePct, null));
        }
        return out;
    }

    /** Largest set of weak cells that are pairwise chained within the neighbour distance. */
    static boolean hasCluster(List<CoverageCellRow> weakCells, List<GatewayPoint> gateways) {
        if (weakCells.size() < CLUSTER_MIN_CELLS) {
            return false;
        }
        // greedy chain count: cells within CLUSTER_NEIGHBOUR_M of each other
        int best = 1;
        for (CoverageCellRow cell : weakCells) {
            int count = 1;
            for (CoverageCellRow other : weakCells) {
                if (cell == other) continue;
                double d = TrackLineCalculator.haversineMeters(
                        cell.centroidLat(), cell.centroidLng(),
                        other.centroidLat(), other.centroidLng());
                if (d <= CLUSTER_NEIGHBOUR_M) count++;
            }
            best = Math.max(best, count);
        }
        return best >= CLUSTER_MIN_CELLS;
    }

    static double[] weakCellsCentroid(List<CoverageCellRow> weakCells) {
        double lat = weakCells.stream().mapToDouble(CoverageCellRow::centroidLat).average().orElse(0);
        double lng = weakCells.stream().mapToDouble(CoverageCellRow::centroidLng).average().orElse(0);
        return new double[]{lat, lng};
    }

    static double nearestGatewayDistanceM(double lat, double lng, List<GatewayPoint> gateways) {
        double best = Double.NaN;
        for (GatewayPoint g : gateways) {
            double d = TrackLineCalculator.haversineMeters(lat, lng, g.lat(), g.lng());
            if (Double.isNaN(best) || d < best) best = d;
        }
        return best;
    }

    static String bearingName(double lat1, double lng1, double lat2, double lng2) {
        double dLng = lng2 - lng1;
        double y = Math.sin(Math.toRadians(dLng)) * Math.cos(Math.toRadians(lat2));
        double x = Math.cos(Math.toRadians(lat1)) * Math.sin(Math.toRadians(lat2))
                - Math.sin(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                    * Math.cos(Math.toRadians(dLng));
        double bearing = (Math.toDegrees(Math.atan2(y, x)) + 360) % 360;
        String[] names = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"};
        return names[(int) Math.round(bearing / 45.0) % 8];
    }

    static String tierOf(double avgRssi) {
        if (avgRssi < -100) return "edge";
        if (avgRssi < -90) return "weak";
        return "stable";
    }

    private static double round1(double v) {
        return Math.round(v * 10.0) / 10.0;
    }

    private static double round5(double v) {
        return Math.round(v * 100000.0) / 100000.0;
    }
}
