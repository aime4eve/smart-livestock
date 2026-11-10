package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface PhysiologyEventJpaRepository extends JpaRepository<PhysiologyEventJpaEntity, Long> {

    /**
     * Record-card list query: newest first, WITHOUT the ALERT_CONFIRM audit
     * rows. {@code ESTRUS_CONFIRM} is the write-only history of human estrus
     * verdicts (NIX-286 contract v2 §7 — ALERT_CONFIRM audit history), while
     * the record card shows manual milestones only, so audit rows must never
     * surface here; the frontend's {@code _unknown → illness} degradation
     * therefore never fires on them. {@link PhysiologyEventService#listEvents}
     * additionally filters defensively in memory, keeping the visible-only
     * contract at the service boundary too.
     */
    @Query("SELECT e FROM PhysiologyEventJpaEntity e"
            + " WHERE e.livestockId = :livestockId"
            + " AND e.eventType <> com.smartlivestock.health.domain.model.PhysiologyEventType.ESTRUS_CONFIRM"
            + " ORDER BY e.occurredAt DESC")
    List<PhysiologyEventJpaEntity> findVisibleByLivestockIdOrderByOccurredAtDesc(
            @Param("livestockId") Long livestockId);

    /**
     * Manual-lane history for read-time window pairing: all MANUAL ILLNESS /
     * RECOVERY rows before the query upper bound, oldest first. Volume is
     * small (manual entry only), so the whole history is paired in memory.
     */
    List<PhysiologyEventJpaEntity> findByLivestockIdAndEventTypeInAndSourceAndOccurredAtLessThanOrderByOccurredAtAsc(
            Long livestockId, Collection<PhysiologyEventType> eventTypes,
            PhysiologySource source, Instant occurredAt);

    /** Farm batch variant of the manual-lane history (avoids N+1). */
    List<PhysiologyEventJpaEntity> findByLivestockIdInAndEventTypeInAndSourceAndOccurredAtLessThanOrderByOccurredAtAsc(
            Collection<Long> livestockIds, Collection<PhysiologyEventType> eventTypes,
            PhysiologySource source, Instant occurredAt);

    /** Dedup / idempotency lookup on (livestock, type, occurredAt, source). */
    Optional<PhysiologyEventJpaEntity> findByLivestockIdAndEventTypeAndOccurredAtAndSource(
            Long livestockId, PhysiologyEventType eventType, Instant occurredAt, PhysiologySource source);

    /**
     * ALERT_CONFIRM audit row referencing one alert (NIX-286) — at most one
     * exists per (livestock, alert) by uq_physiology_alert_confirm.
     */
    Optional<PhysiologyEventJpaEntity> findByLivestockIdAndRefIdAndSource(
            Long livestockId, Long refId, PhysiologySource source);

    /**
     * Latest CALVING or DRY_OFF milestone for stage derivation, restricted
     * to the given source: only MANUAL milestones may drive the lactation/
     * dry stage (NIX-258 m-p) — ALERT_CONFIRM rows, once a write path
     * exists, are read-only history and must not shift the projection.
     */
    Optional<PhysiologyEventJpaEntity> findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
            Long livestockId, Collection<PhysiologyEventType> eventTypes, PhysiologySource source);
}
