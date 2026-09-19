package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.GatewayDistanceProfileRow;
import com.smartlivestock.iot.domain.model.GatewayRegistry;
import com.smartlivestock.iot.domain.model.RssiDistanceSample;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.GatewayDistanceProfileRepository;
import com.smartlivestock.iot.domain.repository.GatewayRegistryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Dynamic RSSI→distance mapping per gateway (NIX-219 plan B, method from
 * Dieng/Pham/Thiare WiMOB 2019): GPS-valid frames are calibration samples,
 * the map is rebuilt daily over a sliding window with recent samples weighted
 * higher, and a log-distance model is the rescue path only when the map has
 * no entry (credible beyond ~100 m per the paper's field data).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GatewayDistanceProfileService {

    static final int BUCKET_GRID_DB = 5;
    static final int MIN_BUCKET_SAMPLES = 5;
    static final double LOG_DISTANCE_MIN_CREDIBLE_M = 100.0;

    private final GatewayRegistryRepository gatewayRegistryRepository;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final GatewayDistanceProfileRepository profileRepository;

    @Value("${smartlivestock.gateway-distance.log-n:4.2}")
    private double logN;

    @Value("${smartlivestock.gateway-distance.log-ref-rssi-1m:-40}")
    private double logRefRssi1m;

    public record Inference(String gatewayId, int rssi, int samples,
                            double p50Meters, double p90Meters, String source) {
    }

    /** Rebuild profiles for every registered gateway. @return gateways processed */
    public int rebuildAll() {
        Instant since = Instant.now().minus(Duration.ofDays(30));
        Instant now = Instant.now();
        int processed = 0;
        for (GatewayRegistry gateway : gatewayRegistryRepository.findAll()) {
            List<RssiDistanceSample> samples =
                    deviceTelemetryLogRepository.rssiDistanceSamples(gateway.getGatewayId(), since);
            List<GatewayDistanceProfileRow> rows = buildProfile(samples, now);
            profileRepository.replaceAll(gateway.getGatewayId(), rows, 30);
            processed++;
            log.info("gateway distance profile rebuilt: gateway={} buckets={} samples={}",
                    gateway.getGatewayId(), rows.size(), samples.size());
        }
        return processed;
    }

    /**
     * Map lookup first; log-distance rescue only when the map has no entry for
     * the RSSI bucket and the estimate is beyond the credible threshold.
     *
     * @return null when neither path can answer (no profile, or sub-100 m rescue)
     */
    public Inference infer(String gatewayId, int rssi) {
        int bucket = bucketOf(rssi);
        for (GatewayDistanceProfileRow row : profileRepository.findByGatewayId(gatewayId)) {
            if (row.bucketRssi() == bucket) {
                return new Inference(gatewayId, rssi, row.sampleCount(),
                        row.p50Meters(), row.p90Meters(), "MAP");
            }
        }
        double rescue = logDistanceMeters(rssi);
        if (rescue < LOG_DISTANCE_MIN_CREDIBLE_M) {
            return null;
        }
        return new Inference(gatewayId, rssi, 0, rescue, rescue * 1.5, "LOG_DISTANCE");
    }

    /** Pure bucketing + quantile computation — unit tested, incl. holdout simulation. */
    static List<GatewayDistanceProfileRow> buildProfile(List<RssiDistanceSample> samples, Instant now) {
        Instant recentHalf = now.minus(Duration.ofDays(15));
        Map<Integer, List<Double>> weighted = new TreeMap<>();
        Map<Integer, Integer> rawCounts = new LinkedHashMap<>();
        for (RssiDistanceSample sample : samples) {
            int bucket = bucketOf(sample.rssi());
            int weight = sample.reportTime() != null && sample.reportTime().isAfter(recentHalf) ? 2 : 1;
            weighted.computeIfAbsent(bucket, k -> new ArrayList<>());
            for (int i = 0; i < weight; i++) {
                weighted.get(bucket).add(sample.distMeters());
            }
            rawCounts.merge(bucket, 1, Integer::sum);
        }
        List<GatewayDistanceProfileRow> rows = new ArrayList<>();
        for (Map.Entry<Integer, List<Double>> entry : weighted.entrySet()) {
            if (rawCounts.getOrDefault(entry.getKey(), 0) < MIN_BUCKET_SAMPLES) {
                continue;
            }
            List<Double> values = new ArrayList<>(entry.getValue());
            values.sort(Comparator.naturalOrder());
            rows.add(new GatewayDistanceProfileRow(
                    entry.getKey(),
                    rawCounts.get(entry.getKey()),
                    quantile(values, 0.5),
                    quantile(values, 0.9)));
        }
        return rows;
    }

    /** Linear-interpolated quantile on a sorted list (percentile_cont semantics). */
    static double quantile(List<Double> sorted, double q) {
        if (sorted.isEmpty()) return Double.NaN;
        if (sorted.size() == 1) return sorted.get(0);
        double pos = q * (sorted.size() - 1);
        int low = (int) Math.floor(pos);
        int high = Math.min(low + 1, sorted.size() - 1);
        double frac = pos - low;
        return sorted.get(low) * (1 - frac) + sorted.get(high) * frac;
    }

    static int bucketOf(int rssi) {
        return Math.floorDiv(rssi, BUCKET_GRID_DB) * BUCKET_GRID_DB;
    }

    /** Log-distance rescue: d = 10^((|rssi| − |rssi@1m|) / (10·n)). */
    double logDistanceMeters(int rssi) {
        return Math.pow(10.0, (Math.abs(rssi) - Math.abs(logRefRssi1m)) / (10.0 * logN));
    }
}
