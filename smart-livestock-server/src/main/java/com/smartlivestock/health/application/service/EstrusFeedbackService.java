package com.smartlivestock.health.application.service;

import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.LabelSource;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import com.smartlivestock.health.domain.model.EstrusScore;
import com.smartlivestock.health.domain.model.PhysiologyEvent;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.domain.repository.EstrusScoreRepository;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.PhysiologyEventJpaRepository;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * Auditable human verdicts on candidate ESTRUS alerts (NIX-286, data
 * contract v2). Submitting a verdict writes, in ONE transaction:
 * an audit-only {@code ALERT_CONFIRM}/{@code ESTRUS_CONFIRM} physiology
 * event row (read-only history, never part of stage derivation or the
 * record card) and a MANUAL ground-truth label carrying the verdict
 * (CONFIRMED / REJECTED) with the restored ≥70-score episode as its period.
 * Re-submitting the same verdict is idempotent (no writes); a flipped
 * verdict supersedes the previous label row and inserts the new one.
 *
 * <p>Deliberately writes labels through {@link GroundTruthLabelRepository}
 * directly and NOT through {@code GroundTruthLabelService}: that service
 * persists with {@code REQUIRES_NEW}, which would commit the label even
 * when the physiology event write (or the rest of this transaction) rolls
 * back, breaking the all-or-nothing contract of a verdict submission.</p>
 *
 * <p>{@link #linkBreedingDerived} is the weak-evidence counterpart: a
 * committed BREEDING event auto-derives no-verdict {@code BREEDING_DERIVED}
 * labels for the estrus alerts raised within the 48h window before it.
 * Those rows are hints for calibration only — they never carry a verdict
 * and their weight must not be treated as equal to MANUAL rulings.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EstrusFeedbackService {

    /** Scores ≥ this threshold formed the alert episodes the verdict rules on. */
    private static final int HIGH_SCORE_THRESHOLD = 70;

    /**
     * Episode alignment tolerance: the same 24h merge gap
     * {@link EstrusSeriesReplayer#mergeEpisodes} uses — an ongoing episode
     * legitimately records high-score positions after the alert row was
     * created (dedup keeps one alert per episode), so an episode ending up
     * to 24h after the alert instant still counts as "immediately preceding".
     */
    private static final Duration EPISODE_ALIGN_TOLERANCE = Duration.ofHours(24);

    /** Estrus alerts looked back from a breeding record (contract v2). */
    private static final Duration BREEDING_LOOKBACK = Duration.ofHours(48);

    /**
     * Cap of the full scoring-history replay. The domain repository limit is
     * applied in-memory over the whole per-animal read, so a generous cap
     * equals "the entire history" while keeping the existing method
     * signature.
     */
    private static final int EPISODE_REPLAY_SCORE_LIMIT = 10_000;

    private final AlertRepository alertRepository;
    private final EstrusScoreRepository estrusScoreRepository;
    private final GroundTruthLabelRepository groundTruthLabelRepository;
    private final PhysiologyEventJpaRepository physiologyEventRepository;
    private final EstrusSeriesReplayer estrusSeriesReplayer;

    /** Outcome of one verdict submission. */
    public record FeedbackResult(Long alertId, String verdict, Long physiologyEventId,
                                 Long labelId, boolean idempotent) {
    }

    /** Restored label period: the episode bounds or the alert point window. */
    record Window(Instant start, Instant end) {
    }

    /**
     * Records an auditable verdict on one ESTRUS alert. See the class javadoc
     * for the write set and the idempotency/reversal matrix.
     */
    @Transactional
    public FeedbackResult submitFeedback(Long farmId, Long alertId, boolean confirmed, Long userId) {
        // a) alert validation — existence, type, farm scope.
        Alert alert = alertRepository.findById(alertId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.estrusFeedback.alertNotFound"));
        if (alert.getType() != AlertType.ESTRUS) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "error.estrusFeedback.notEstrusAlert");
        }
        if (!farmId.equals(alert.getFarmId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN,
                    "error.estrusFeedback.farmMismatch");
        }
        String verdict = confirmed ? GroundTruthLabel.VERDICT_CONFIRMED : GroundTruthLabel.VERDICT_REJECTED;

        // b) episode restore → the label period (episode bounds or point window).
        Instant alertCreatedAt = alert.getCreatedAt() != null ? alert.getCreatedAt() : Instant.now();
        Window period = resolveEpisodeWindow(alert.getLivestockId(), alertCreatedAt);

        // c) existing effective verdict row for this alert (at most one by
        //    uq_gt_labels_alert_active): same verdict → idempotent no-write
        //    return; flipped verdict → supersede + re-insert below.
        Optional<GroundTruthLabel> active = groundTruthLabelRepository.findActiveVerdictByRefAlertId(alertId);
        if (active.isPresent() && verdict.equals(active.get().getVerdict())) {
            Long existingEventId = physiologyEventRepository
                    .findByLivestockIdAndRefIdAndSource(alert.getLivestockId(), alertId,
                            PhysiologySource.ALERT_CONFIRM)
                    .map(PhysiologyEventJpaEntity::getId)
                    .orElse(null);
            return new FeedbackResult(alertId, verdict, existingEventId, active.get().getId(), true);
        }

        // d) physiology audit row: reuse the existing ALERT_CONFIRM row for
        //    this alert or insert a fresh ESTRUS_CONFIRM one (race → re-read).
        Long physiologyEventId = upsertAlertConfirmEvent(alert, confirmed, userId);

        // e) label write; a reversal first marks the old row SUPERSEDED —
        //    same transaction, so old row and new row commit together.
        if (active.isPresent()) {
            GroundTruthLabel superseded = active.get();
            superseded.setVerdict(GroundTruthLabel.VERDICT_SUPERSEDED);
            groundTruthLabelRepository.save(superseded);
        }
        GroundTruthLabel label = new GroundTruthLabel();
        label.setLivestockId(alert.getLivestockId());
        label.setType(ScenarioType.ESTRUS);
        label.setPeriodStart(period.start());
        label.setPeriodEnd(period.end());
        label.setSource(LabelSource.MANUAL);
        label.setVerdict(verdict);
        label.setRefAlertId(alertId);
        label.setSeverity(confirmed ? 1.0 : 0.0);
        label.setLabeledBy(userId);
        label.setLabeledAt(Instant.now());
        label.setNote("alert #" + alertId + " feedback");
        GroundTruthLabel saved = groundTruthLabelRepository.save(label);
        return new FeedbackResult(alertId, verdict, physiologyEventId, saved.getId(), false);
    }

    /**
     * Auto-derives weak-evidence {@code BREEDING_DERIVED} labels for the
     * ESTRUS alerts raised within {@code breedingAt − 48h .. breedingAt}
     * (anchored on occurred_at — breeding may be backdated). Runs in its own
     * {@code REQUIRES_NEW} transaction: callers invoke it from an
     * afterCommit hook (or, without an active synchronization, inline right
     * after the breeding event row exists), so the derived labels commit
     * independently of — and never roll back — the breeding event itself.
     * Each alert is decided independently: alerts already carrying a human
     * verdict or an existing BREEDING_DERIVED row are skipped, and a single
     * failing alert is logged and counted without aborting the rest.
     *
     * @return number of newly written BREEDING_DERIVED labels
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int linkBreedingDerived(Long livestockId, Instant breedingAt, Long userId) {
        if (livestockId == null || breedingAt == null) {
            return 0;
        }
        List<Alert> candidates = alertRepository.findByLivestockIdAndTypeAndCreatedAtBetween(
                livestockId, AlertType.ESTRUS, breedingAt.minus(BREEDING_LOOKBACK), breedingAt);
        int linked = 0;
        for (Alert alert : candidates) {
            try {
                if (alert.getCreatedAt() == null || alert.getId() == null) {
                    continue;
                }
                // A human verdict already exists → the manual ruling wins.
                if (groundTruthLabelRepository.findActiveVerdictByRefAlertId(alert.getId()).isPresent()) {
                    continue;
                }
                // Already derived (by this or an earlier breeding record) → skip.
                if (groundTruthLabelRepository.findByRefAlertIdAndSource(
                        alert.getId(), LabelSource.BREEDING_DERIVED).isPresent()) {
                    continue;
                }
                GroundTruthLabel label = new GroundTruthLabel();
                label.setLivestockId(livestockId);
                label.setType(ScenarioType.ESTRUS);
                label.setPeriodStart(alert.getCreatedAt());
                label.setPeriodEnd(alert.getCreatedAt());
                label.setSource(LabelSource.BREEDING_DERIVED);
                label.setVerdict(null);
                label.setRefAlertId(alert.getId());
                label.setSeverity(0.0);
                label.setLabeledBy(userId);
                label.setLabeledAt(Instant.now());
                label.setNote("derived from breeding record");
                groundTruthLabelRepository.save(label);
                linked++;
            } catch (Exception failure) {
                log.warn("BREEDING_DERIVED linking failed for alert #{} (livestock {}); continuing",
                        alert.getId(), livestockId, failure);
            }
        }
        if (linked > 0) {
            log.info("Derived {} BREEDING_DERIVED label(s) from breeding record of livestock {} at {}",
                    linked, livestockId, breedingAt);
        }
        return linked;
    }

    // ── Episode restoration ─────────────────────────────────────

    /**
     * Rebuilds the ≥70-score episodes of the animal from its full scoring
     * history and picks the window the verdict rules on: the episode covering
     * the alert instant wins; otherwise the nearest episode whose end does
     * not trail the alert instant by more than the 24h merge gap; when no
     * episode restores (no scores, nothing ≥70, or any restore failure) the
     * window collapses to the alert point window. A restore failure must
     * never fail the verdict submission — the point window is the contract.
     */
    private Window resolveEpisodeWindow(Long livestockId, Instant alertCreatedAt) {
        try {
            List<Instant> highScoreTimes = estrusScoreRepository
                    .findByLivestockIdOrderByScoredAtDesc(livestockId, EPISODE_REPLAY_SCORE_LIMIT)
                    .stream()
                    .filter(score -> score.getScore() != null
                            && score.getScore() >= HIGH_SCORE_THRESHOLD
                            && score.getScoredAt() != null)
                    .map(EstrusScore::getScoredAt)
                    .toList();
            List<EstrusSeriesReplayer.EpisodeRecord> episodes =
                    EstrusSeriesReplayer.mergeEpisodes(null, highScoreTimes);
            return selectEpisodeWindow(episodes, alertCreatedAt);
        } catch (Exception restoreFailure) {
            log.warn("Estrus episode restore failed for livestock {}; using the alert point window",
                    livestockId, restoreFailure);
            return new Window(alertCreatedAt, alertCreatedAt);
        }
    }

    /**
     * Covering episode first (start ≤ alert ≤ end), then the nearest episode
     * by end within the merge-gap tolerance (contract v2 "immediately
     * preceding"), else the point window.
     */
    private static Window selectEpisodeWindow(List<EstrusSeriesReplayer.EpisodeRecord> episodes,
                                              Instant alertCreatedAt) {
        Optional<EstrusSeriesReplayer.EpisodeRecord> covering = episodes.stream()
                .filter(episode -> !episode.start().isAfter(alertCreatedAt)
                        && !episode.end().isBefore(alertCreatedAt))
                .findFirst();
        if (covering.isPresent()) {
            return new Window(covering.get().start(), covering.get().end());
        }
        Instant upperBound = alertCreatedAt.plus(EPISODE_ALIGN_TOLERANCE);
        return episodes.stream()
                .filter(episode -> !episode.end().isAfter(upperBound))
                .max(Comparator.comparing(EstrusSeriesReplayer.EpisodeRecord::end))
                .map(episode -> new Window(episode.start(), episode.end()))
                .orElse(new Window(alertCreatedAt, alertCreatedAt));
    }

    // ── Physiology audit row ────────────────────────────────────

    /**
     * Reuses the existing (livestock, alertId) ALERT_CONFIRM row or inserts a
     * fresh ESTRUS_CONFIRM audit row. A concurrent duplicate slipping past
     * the pre-check is caught on {@code uq_physiology_alert_confirm} and
     * resolved by re-reading the winning row, mirroring the
     * {@code PhysiologyEventService.createEvent} race style.
     */
    private Long upsertAlertConfirmEvent(Alert alert, boolean confirmed, Long userId) {
        Optional<PhysiologyEventJpaEntity> existing = physiologyEventRepository
                .findByLivestockIdAndRefIdAndSource(alert.getLivestockId(), alert.getId(),
                        PhysiologySource.ALERT_CONFIRM);
        if (existing.isPresent()) {
            return existing.get().getId();
        }
        PhysiologyEvent event = new PhysiologyEvent();
        event.setLivestockId(alert.getLivestockId());
        event.setEventType(PhysiologyEventType.ESTRUS_CONFIRM);
        event.setOccurredAt(alert.getCreatedAt() != null ? alert.getCreatedAt() : Instant.now());
        event.setSource(PhysiologySource.ALERT_CONFIRM);
        event.setRefId(alert.getId());
        event.setNote("estrus feedback: " + (confirmed ? "confirmed" : "rejected")
                + " (alert #" + alert.getId() + ")");
        event.setCreatedBy(userId);
        event.setUpdatedBy(userId);
        try {
            return physiologyEventRepository.save(toJpa(event)).getId();
        } catch (DataIntegrityViolationException race) {
            // Lost a concurrent insert on uq_physiology_alert_confirm: the
            // winner is committed (Postgres unique waits for the other tx) —
            // re-read the winning audit row and keep the idempotent contract.
            return physiologyEventRepository
                    .findByLivestockIdAndRefIdAndSource(alert.getLivestockId(), alert.getId(),
                            PhysiologySource.ALERT_CONFIRM)
                    .map(PhysiologyEventJpaEntity::getId)
                    .orElseThrow(() -> race);
        }
    }

    private static PhysiologyEventJpaEntity toJpa(PhysiologyEvent event) {
        PhysiologyEventJpaEntity entity = new PhysiologyEventJpaEntity();
        entity.setId(event.getId());
        entity.setLivestockId(event.getLivestockId());
        entity.setEventType(event.getEventType());
        entity.setOccurredAt(event.getOccurredAt());
        entity.setSource(event.getSource());
        entity.setRefId(event.getRefId());
        entity.setNote(event.getNote());
        entity.setCreatedBy(event.getCreatedBy());
        entity.setUpdatedBy(event.getUpdatedBy());
        return entity;
    }
}
