package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface DrinkingEventJpaRepository extends JpaRepository<DrinkingEventJpaEntity, Long> {

    /**
     * All rows of one device overlapping the recalculation delete window
     * {@code [from, to)} — used for the label snapshot (§15.4). MANUAL rows
     * are included so the snapshot can skip them explicitly.
     */
    List<DrinkingEventJpaEntity> findByDeviceIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThan(
            Long deviceId, Instant from, Instant to);

    /**
     * F6 recalc delete: algorithm-produced rows only ({@code source != MANUAL})
     * in the overlap-extended window. MANUAL rows are never deleted.
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("DELETE FROM DrinkingEventJpaEntity e " +
            "WHERE e.deviceId = :deviceId " +
            "AND e.eventStartAt >= :from AND e.eventStartAt < :to " +
            "AND e.source <> 'MANUAL'")
    int deleteAlgorithmRowsInWindow(@Param("deviceId") Long deviceId,
                                    @Param("from") Instant from, @Param("to") Instant to);
}
