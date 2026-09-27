package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.SignalEventOutboxJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface SignalEventOutboxJpaRepository
        extends JpaRepository<SignalEventOutboxJpaEntity, Long> {

    @Query(value = """
            INSERT INTO signal_event_outbox (
                farm_id, event_type, entity_type, entity_id, payload
            ) VALUES (
                :farmId, :eventType, :entityType, :entityId,
                CAST(:payload AS jsonb)
            )
            ON CONFLICT (farm_id, event_type, entity_type, entity_id)
                WHERE status = 'PENDING'
            DO UPDATE SET
                payload = EXCLUDED.payload,
                available_at = LEAST(signal_event_outbox.available_at, NOW()),
                updated_at = NOW()
            RETURNING id
            """, nativeQuery = true)
    Long upsertPending(
            @Param("farmId") Long farmId,
            @Param("eventType") String eventType,
            @Param("entityType") String entityType,
            @Param("entityId") Long entityId,
            @Param("payload") String payload);

    @Query(value = """
            SELECT id
            FROM signal_event_outbox
            WHERE status = 'PENDING'
              AND available_at <= NOW()
            ORDER BY id
            LIMIT :limit
            FOR UPDATE SKIP LOCKED
            """, nativeQuery = true)
    java.util.List<Long> findDispatchableIds(@Param("limit") int limit);
}
