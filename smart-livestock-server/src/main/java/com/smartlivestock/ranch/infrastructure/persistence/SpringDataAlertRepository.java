package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.AlertJpaEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface SpringDataAlertRepository extends JpaRepository<AlertJpaEntity, Long> {
    List<AlertJpaEntity> findByFarmId(Long farmId);
    List<AlertJpaEntity> findByLivestockIdAndTypeAndStatus(Long livestockId, String type, String status);
    List<AlertJpaEntity> findByDeviceIdAndTypeAndStatus(Long deviceId, String type, String status);
    List<AlertJpaEntity> findByLivestockIdAndStatusAndSource(Long livestockId, String status, String source);

    // ── Aggregated counters (alert summary endpoint) ──

    interface AlertCountProjection {
        String getStatus();
        String getSeverity();
        String getType();
        long getCnt();
    }

    interface AlertUnreadTypeProjection {
        String getType();
        long getCnt();
    }

    @Query("SELECT a.status AS status, a.severity AS severity, a.type AS type, COUNT(a) AS cnt "
            + "FROM AlertJpaEntity a WHERE a.farmId = :farmId AND a.type IN :types "
            + "GROUP BY a.status, a.severity, a.type")
    List<AlertCountProjection> countByFarmGrouped(@Param("farmId") Long farmId,
                                                  @Param("types") Collection<String> types);

    @Query("SELECT a.type AS type, COUNT(a) AS cnt FROM AlertJpaEntity a "
            + "WHERE a.farmId = :farmId AND a.status = 'ACTIVE' AND a.type IN :types AND a.id NOT IN "
            + "(SELECT ars.alertId FROM AlertReadStatusJpaEntity ars WHERE ars.userId = :userId) "
            + "GROUP BY a.type")
    List<AlertUnreadTypeProjection> countActiveUnreadGroupedByType(@Param("farmId") Long farmId,
                                                                   @Param("userId") Long userId,
                                                                   @Param("types") Collection<String> types);

    // ── True pagination (empty collection ≙ no filter; callers always pass all values) ──

    @Query("SELECT a FROM AlertJpaEntity a WHERE a.farmId = :farmId "
            + "AND a.status IN :statuses AND a.severity IN :severities AND a.type IN :types "
            + "AND (:fenceId IS NULL OR a.fenceId = :fenceId) "
            + "AND (:unreadOnly = false OR a.id NOT IN "
            + "(SELECT ars.alertId FROM AlertReadStatusJpaEntity ars WHERE ars.userId = :readerId)) "
            + "ORDER BY a.id DESC")
    List<AlertJpaEntity> pageByFilters(@Param("farmId") Long farmId,
                                       @Param("statuses") Collection<String> statuses,
                                       @Param("severities") Collection<String> severities,
                                       @Param("types") Collection<String> types,
                                       @Param("fenceId") Long fenceId,
                                       @Param("unreadOnly") boolean unreadOnly,
                                       @Param("readerId") Long readerId,
                                       Pageable pageable);

    @Query("SELECT COUNT(a) FROM AlertJpaEntity a WHERE a.farmId = :farmId "
            + "AND a.status IN :statuses AND a.severity IN :severities AND a.type IN :types "
            + "AND (:fenceId IS NULL OR a.fenceId = :fenceId) "
            + "AND (:unreadOnly = false OR a.id NOT IN "
            + "(SELECT ars.alertId FROM AlertReadStatusJpaEntity ars WHERE ars.userId = :readerId))")
    long countByFilters(@Param("farmId") Long farmId,
                        @Param("statuses") Collection<String> statuses,
                        @Param("severities") Collection<String> severities,
                        @Param("types") Collection<String> types,
                        @Param("fenceId") Long fenceId,
                        @Param("unreadOnly") boolean unreadOnly,
                        @Param("readerId") Long readerId);

    @Modifying
    @Query("DELETE FROM AlertJpaEntity a WHERE a.fenceId = :fenceId")
    int deleteByFenceId(@Param("fenceId") Long fenceId);

    @Modifying
    @Query("UPDATE AlertJpaEntity a SET a.fenceId = NULL WHERE a.fenceId = :fenceId")
    int clearFenceReference(@Param("fenceId") Long fenceId);
}
