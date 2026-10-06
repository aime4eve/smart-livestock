package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface PhysiologyEventJpaRepository extends JpaRepository<PhysiologyEventJpaEntity, Long> {

    /** List endpoint: newest first, client truncates to three rows. */
    List<PhysiologyEventJpaEntity> findByLivestockIdOrderByOccurredAtDesc(Long livestockId);

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
     * Latest CALVING or DRY_OFF milestone for stage derivation, restricted
     * to the given source: only MANUAL milestones may drive the lactation/
     * dry stage (NIX-258 m-p) — ALERT_CONFIRM rows, once a write path
     * exists, are read-only history and must not shift the projection.
     */
    Optional<PhysiologyEventJpaEntity> findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
            Long livestockId, Collection<PhysiologyEventType> eventTypes, PhysiologySource source);
}
