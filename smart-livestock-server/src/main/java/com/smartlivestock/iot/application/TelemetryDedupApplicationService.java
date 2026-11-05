package com.smartlivestock.iot.application;

import com.smartlivestock.iot.infrastructure.persistence.SpringDataTelemetryIngestionDedupRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.TelemetryIngestionDedupJpaEntity;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Observation arbitration for the THINGSBOARD ingest path (NIX-370), ported
 * from smart-parking's TelemetryDedupApplicationService (NIX-120/125/252).
 *
 * The upstream write path (NS → OC bridge → TB) was proven to re-write one
 * physical frame as two full data points ~134ms apart (result×2 + dataHex×2,
 * identical payload and wireless params), so provider_event_ts alone cannot
 * identify a frame — exact-ts idempotency lets the second point through.
 * Each observation is therefore arbitrated here first: within the ±2s match
 * window and an equal core-fields fingerprint it merges into the standing
 * canonical event; only CANONICAL observations may proceed to
 * device_telemetry_logs (same transaction, so an ingest failure rolls the
 * arbitration back and the frame is retried — nothing is lost).
 *
 * Deliberately wired ONLY into the TbTelemetryChannel (tb-rest) path: the
 * AGENTIC_PLATFORM + THINGSBOARD dual-track write is an existing design and
 * must keep producing two rows per frame.
 */
@Service
@Slf4j
public class TelemetryDedupApplicationService {

    public record Observation(
            Long deviceId,
            String provider,
            String channel,
            String externalDeviceId,
            Instant eventTs,
            long providerEventTs,
            String coreFieldsFingerprint
    ) {}

    public enum Result { CANONICAL, MATCHED_DUPLICATE, SOURCE_DUPLICATE, AMBIGUOUS }

    /** Same-window rule as parking: upstream re-writes land ~134ms apart. */
    private static final long MATCH_WINDOW_MS = 2_000;

    /**
     * Core business payload fields only. Wireless params (rssi/snr) are
     * deliberately excluded — the observed duplicates differ only there, and
     * they are receive-side evidence, not business content.
     */
    private static final String[] CORE_FIELDS = {
            "battery", "stepNumber", "gastricMotility", "latitude", "longitude",
            "accelXRaw", "accelYRaw", "accelZRaw",
            "workMode", "antiDisassemblyStatus", "hardware", "software"
    };

    /**
     * Single channel today (tb-rest); kept as a map to preserve the parking
     * arbitration structure for future channels (tb-ws / devicehub MQ).
     */
    private static final Map<String, Integer> CHANNEL_PRIORITY = Map.of(
            "tb-rest", 3);

    private final SpringDataTelemetryIngestionDedupRepository repository;

    public TelemetryDedupApplicationService(SpringDataTelemetryIngestionDedupRepository repository) {
        this.repository = repository;
    }

    public static String coreFieldsFingerprint(Map<String, Object> properties) {
        try {
            Map<String, Object> sorted = new TreeMap<>();
            for (String field : CORE_FIELDS) {
                sorted.put(field, properties == null ? null : properties.get(field));
            }
            String raw = String.valueOf(sorted);
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(raw.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 is unavailable", e);
        }
    }

    /**
     * Arbitrate one observation. Runs in the caller's transaction
     * (REQUIRED): the ingest that follows a CANONICAL result shares this
     * transaction, so a failure anywhere rolls the arbitration back too and
     * the frame is retried on the next poll — no lost frames, no wedged
     * cursor, no orphaned canonical rows.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public Result register(Observation observation) {
        acquireArbitrationLocks(observation);
        var sourceKey = repository.findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
                observation.provider(), observation.externalDeviceId(),
                observation.providerEventTs(), observation.channel());
        if (sourceKey.isPresent()) {
            return Result.SOURCE_DUPLICATE;
        }

        var candidates = repository.findByDeviceIdAndCanonical(observation.deviceId(), true).stream()
                .filter(candidate -> isNeighbor(candidate, observation))
                .filter(candidate -> observation.coreFieldsFingerprint() == null
                        || observation.coreFieldsFingerprint().equals(candidate.getCoreFieldsFingerprint()))
                .toList();

        String ownKey = canonicalKey(observation);
        if (candidates.size() > 1) {
            TelemetryIngestionDedupJpaEntity ambiguous = entity(observation, ownKey, false, null);
            repository.save(ambiguous);
            log.warn("Ambiguous telemetry observation device={} ts={}: {} candidates",
                    observation.deviceId(), observation.eventTs(), candidates.size());
            return Result.AMBIGUOUS;
        }

        if (!candidates.isEmpty()) {
            var winner = candidates.get(0);
            if (CHANNEL_PRIORITY.getOrDefault(observation.channel(), 0)
                    > CHANNEL_PRIORITY.getOrDefault(winner.getChannel(), 0)) {
                winner.setCanonical(false);
                winner.setMatchedCanonicalKey(ownKey);
                repository.save(winner);
            } else {
                TelemetryIngestionDedupJpaEntity duplicate = entity(
                        observation, winner.getCanonicalKey(), false, winner.getCanonicalKey());
                repository.save(duplicate);
                return Result.MATCHED_DUPLICATE;
            }
        }

        // Same-canonical-key guard (parking NIX-252): sibling observations of
        // one provider share the canonical-key space
        // (provider|externalDeviceId|providerEventTs); a fingerprint drift
        // filtered the neighbor out above, and falling through would insert a
        // second canonical row with the SAME key → uq_dedup_canonical_event
        // violation → poll cycle fails → cursor wedged. This observation IS
        // that frame: record it as a duplicate of the standing canonical.
        var standing = repository.findByCanonicalKeyAndCanonical(ownKey, true);
        if (standing.isPresent()) {
            repository.save(entity(observation, standing.get().getCanonicalKey(),
                    false, standing.get().getCanonicalKey()));
            return Result.MATCHED_DUPLICATE;
        }

        repository.save(entity(observation, ownKey, true, null));
        return Result.CANONICAL;
    }

    private void acquireArbitrationLocks(Observation observation) {
        repository.acquireAdvisoryLock("telemetry:source:" + observation.provider()
                + "|" + observation.externalDeviceId() + "|" + observation.providerEventTs()
                + "|" + observation.channel());
        repository.acquireAdvisoryLock("telemetry:canonical:" + observation.deviceId());
    }

    private boolean isNeighbor(TelemetryIngestionDedupJpaEntity candidate, Observation observation) {
        return Math.abs(candidate.getProviderEventTs() - observation.providerEventTs()) <= MATCH_WINDOW_MS;
    }

    private TelemetryIngestionDedupJpaEntity entity(
            Observation observation, String key, boolean canonical, String matchedKey) {
        TelemetryIngestionDedupJpaEntity entity = new TelemetryIngestionDedupJpaEntity();
        entity.setProvider(observation.provider());
        entity.setChannel(observation.channel());
        entity.setDeviceId(observation.deviceId());
        entity.setExternalDeviceId(observation.externalDeviceId());
        entity.setEventTs(observation.eventTs());
        entity.setProviderEventTs(observation.providerEventTs());
        entity.setCanonicalKey(key);
        entity.setCanonical(canonical);
        entity.setCoreFieldsFingerprint(observation.coreFieldsFingerprint());
        entity.setMatchedCanonicalKey(canonical ? null : matchedKey);
        return entity;
    }

    private String canonicalKey(Observation observation) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            String raw = observation.provider() + "|" + observation.externalDeviceId()
                    + "|" + observation.providerEventTs();
            return HexFormat.of().formatHex(digest.digest(raw.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 is unavailable", e);
        }
    }
}
