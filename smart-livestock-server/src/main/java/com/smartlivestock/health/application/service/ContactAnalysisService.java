package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ContactTrace;
import com.smartlivestock.health.domain.port.GpsTrajectoryPort;
import com.smartlivestock.health.domain.port.GpsTrajectoryPort.GpsPoint;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.repository.ContactTraceRepository;
import com.smartlivestock.health.domain.service.ContactRiskScoring;
import com.smartlivestock.iot.domain.service.TrackLineCalculator;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Contact analysis kernel shared by both tracks of the epidemic design
 * (spec §4, 2026-09-29): the resident scheduler (rolling re-computation of
 * the contact pool) and the mark-diseased snapshot track.
 * <p>
 * Reads {@code gps_logs} through {@link GpsTrajectoryPort} (livestock ->
 * active tracker/ear-tag -> device), aligns the two trajectories of each
 * livestock pair on a fixed time granularity, and counts a pair as a contact
 * when the minimum in-bucket distance stays within the proximity threshold
 * for at least the minimum cumulative duration.
 * <p>
 * Upsert semantics: only rows with {@code marked_at IS NULL} are written;
 * marked rows keep their epidemic semantics untouched. The pair direction is
 * normalized (smaller livestockId = from) so re-analysis refreshes the same
 * row instead of stacking duplicates.
 */
@Slf4j
@Service
public class ContactAnalysisService {

    private final ContactTraceRepository contactTraceRepo;
    private final GpsTrajectoryPort gpsTrajectoryPort;
    private final RanchQueryPort ranchQueryPort;

    private final double proximityThresholdMeters;
    private final int minDurationMinutes;
    private final long alignGranularitySeconds;

    public ContactAnalysisService(
            ContactTraceRepository contactTraceRepo,
            GpsTrajectoryPort gpsTrajectoryPort,
            RanchQueryPort ranchQueryPort,
            @Value("${health.contact.proximity-threshold-meters:30}") double proximityThresholdMeters,
            @Value("${health.contact.min-duration-minutes:5}") int minDurationMinutes,
            @Value("${health.contact.align-granularity-seconds:60}") long alignGranularitySeconds) {
        this.contactTraceRepo = contactTraceRepo;
        this.gpsTrajectoryPort = gpsTrajectoryPort;
        this.ranchQueryPort = ranchQueryPort;
        this.proximityThresholdMeters = proximityThresholdMeters;
        this.minDurationMinutes = minDurationMinutes;
        this.alignGranularitySeconds = alignGranularitySeconds;
    }

    /** One detected contact pair, before persistence. */
    public record ContactAnalysisResult(
            Long fromLivestockId,
            Long toLivestockId,
            BigDecimal proximityMeters,
            int contactDurationMinutes,
            Instant lastContactAt,
            int riskScore,
            String riskLevel) {}

    /**
     * Analyze contacts since {@code cutoff} and idempotently upsert the
     * resulting rows into {@code contact_traces}.
     *
     * @param farmId     owning farm
     * @param livestockId target livestock, or {@code null} for whole-herd
     *                     pairwise analysis
     * @param cutoff     window start; points recorded before it are ignored
     * @return number of contact rows inserted or updated (marked rows are
     *         skipped and not counted)
     */
    @Transactional
    public int analyzeAndStore(Long farmId, Long livestockId, Instant cutoff) {
        long startedAt = System.currentTimeMillis();
        Instant now = Instant.now();

        List<Long> livestockIds = resolveLivestockIds(farmId, livestockId);
        if (livestockIds.size() < 2) {
            log.info("Contact analysis skipped for farm [{}]: fewer than 2 livestock candidates", farmId);
            return 0;
        }

        // Load trajectories once per involved livestock (null-safe: missing
        // device binding simply yields no points and drops out of the pairs).
        Map<Long, TreeMap<Long, List<GpsPoint>>> bucketedTrajectories = new HashMap<>();
        for (Long id : livestockIds) {
            List<GpsPoint> trajectory = gpsTrajectoryPort.findTrajectory(id, cutoff, now);
            if (!trajectory.isEmpty()) {
                bucketedTrajectories.put(id, bucketByGranularity(trajectory));
            }
        }
        if (bucketedTrajectories.size() < 2) {
            log.info("Contact analysis skipped for farm [{}]: no GPS trajectories in window since {}", farmId, cutoff);
            return 0;
        }

        List<ContactAnalysisResult> results = new ArrayList<>();
        List<Long> withGps = livestockIds.stream().filter(bucketedTrajectories::containsKey).toList();
        for (int i = 0; i < withGps.size(); i++) {
            for (int j = i + 1; j < withGps.size(); j++) {
                // Targeted scope: only pairs the target livestock participates in.
                if (livestockId != null
                        && !withGps.get(i).equals(livestockId)
                        && !withGps.get(j).equals(livestockId)) {
                    continue;
                }
                ContactAnalysisResult result = analyzePair(
                        withGps.get(i), withGps.get(j),
                        bucketedTrajectories.get(withGps.get(i)),
                        bucketedTrajectories.get(withGps.get(j)), now);
                if (result != null) {
                    results.add(result);
                }
            }
        }

        int written = upsertResults(farmId, results);
        log.info("Contact analysis for farm [{}] window [{}..{}]: candidates={} withGps={} contacts={} written={} elapsedMs={}",
                farmId, cutoff, now, livestockIds.size(), withGps.size(), results.size(), written,
                System.currentTimeMillis() - startedAt);
        return written;
    }

    /**
     * Target scope: single livestock paired against the whole farm, or the
     * whole farm pairwise. Sorted for deterministic pair enumeration.
     */
    private List<Long> resolveLivestockIds(Long farmId, Long livestockId) {
        List<Long> farmIds = ranchQueryPort.findAllByFarmId(farmId).stream()
                .map(info -> info.id())
                .distinct()
                .sorted()
                .toList();
        if (livestockId == null) {
            return farmIds;
        }
        if (!farmIds.contains(livestockId)) {
            return List.of(livestockId);
        }
        return farmIds;
    }

    /**
     * Group trajectory points into fixed buckets keyed by
     * {@code epochSecond / granularity}. A {@link TreeMap} keeps bucket
     * traversal in chronological order.
     */
    private TreeMap<Long, List<GpsPoint>> bucketByGranularity(List<GpsPoint> trajectory) {
        TreeMap<Long, List<GpsPoint>> buckets = new TreeMap<>();
        for (GpsPoint point : trajectory) {
            long bucket = Math.floorDiv(point.recordedAt().getEpochSecond(), alignGranularitySeconds);
            buckets.computeIfAbsent(bucket, k -> new ArrayList<>()).add(point);
        }
        return buckets;
    }

    /**
     * Pair analysis: for every time bucket where both animals have fixes,
     * take the minimum pairwise haversine distance; buckets at or below the
     * proximity threshold count as contact time. Returns {@code null} when
     * the cumulative contact duration stays under the configured minimum.
     */
    private ContactAnalysisResult analyzePair(Long idA, Long idB,
                                              TreeMap<Long, List<GpsPoint>> bucketsA,
                                              TreeMap<Long, List<GpsPoint>> bucketsB,
                                              Instant now) {
        double minDistance = Double.MAX_VALUE;
        long contactBuckets = 0;
        Instant lastContactAt = null;

        for (Map.Entry<Long, List<GpsPoint>> entry : bucketsA.entrySet()) {
            List<GpsPoint> otherBucket = bucketsB.get(entry.getKey());
            if (otherBucket == null) {
                continue;
            }
            double bucketMin = Double.MAX_VALUE;
            Instant bucketLatest = null;
            for (GpsPoint a : entry.getValue()) {
                for (GpsPoint b : otherBucket) {
                    double distance = TrackLineCalculator.haversineMeters(
                            a.latitude(), a.longitude(), b.latitude(), b.longitude());
                    if (distance < bucketMin) {
                        bucketMin = distance;
                    }
                }
                bucketLatest = laterOf(bucketLatest, a.recordedAt());
            }
            for (GpsPoint b : otherBucket) {
                bucketLatest = laterOf(bucketLatest, b.recordedAt());
            }
            minDistance = Math.min(minDistance, bucketMin);
            if (bucketMin <= proximityThresholdMeters) {
                contactBuckets++;
                lastContactAt = laterOf(lastContactAt, bucketLatest);
            }
        }

        long contactSeconds = contactBuckets * alignGranularitySeconds;
        long durationMinutes = contactSeconds / 60;
        if (durationMinutes < minDurationMinutes) {
            return null;
        }

        long from = Math.min(idA, idB);
        long to = Math.max(idA, idB);
        BigDecimal proximity = BigDecimal.valueOf(minDistance).setScale(2, RoundingMode.HALF_UP);
        int hoursAgo = (int) Duration.between(lastContactAt, now).toHours();
        int totalScore = ContactRiskScoring.totalScore(hoursAgo, proximity, (int) durationMinutes);
        return new ContactAnalysisResult(from, to, proximity,
                (int) durationMinutes, lastContactAt, totalScore,
                ContactRiskScoring.riskLevel(totalScore));
    }

    /**
     * Idempotent upsert: insert a fresh unmarked row per pair, or refresh the
     * existing unmarked row in place. Rows with {@code marked_at} set keep
     * their values (epidemic semantics survive rolling re-computation).
     *
     * @return number of rows inserted or updated
     */
    private int upsertResults(Long farmId, List<ContactAnalysisResult> results) {
        if (results.isEmpty()) {
            return 0;
        }

        // Pair key -> existing row. First row wins on (unexpected) legacy
        // duplicates; marked duplicates are simply never written.
        Map<String, ContactTrace> existingByPair = new LinkedHashMap<>();
        for (ContactTrace trace : contactTraceRepo.findByFarmIdOrderByLastContactAtDesc(farmId)) {
            existingByPair.putIfAbsent(pairKey(trace.getFromLivestockId(), trace.getToLivestockId()), trace);
        }

        int written = 0;
        for (ContactAnalysisResult result : results) {
            ContactTrace existing = existingByPair.get(pairKey(result.fromLivestockId(), result.toLivestockId()));
            if (existing != null && existing.getMarkedAt() != null) {
                continue;
            }
            ContactTrace row = existing != null ? existing : new ContactTrace();
            row.setFarmId(farmId);
            row.setFromLivestockId(result.fromLivestockId());
            row.setToLivestockId(result.toLivestockId());
            row.setProximityMeters(result.proximityMeters());
            row.setContactDurationMinutes(result.contactDurationMinutes());
            row.setLastContactAt(result.lastContactAt());
            row.setRiskScore(result.riskScore());
            row.setRiskLevel(result.riskLevel());
            // Pool rows carry no epidemic semantics: diseaseType/markedAt stay null.
            row.setDiseaseType(null);
            row.setMarkedAt(null);
            contactTraceRepo.save(row);
            written++;
        }
        return written;
    }

    private static String pairKey(Long from, Long to) {
        return from + "->" + to;
    }

    private static Instant laterOf(Instant a, Instant b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.isAfter(b) ? a : b;
    }
}
