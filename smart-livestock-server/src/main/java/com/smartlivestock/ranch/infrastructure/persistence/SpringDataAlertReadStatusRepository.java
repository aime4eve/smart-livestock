package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.AlertReadStatusJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Set;

public interface SpringDataAlertReadStatusRepository extends JpaRepository<AlertReadStatusJpaEntity, Long> {

    boolean existsByAlertIdAndUserId(Long alertId, Long userId);

    List<AlertReadStatusJpaEntity> findByUserIdAndAlertIdIn(Long userId, Collection<Long> alertIds);

    @Query("SELECT DISTINCT ars.alertId FROM AlertReadStatusJpaEntity ars WHERE ars.userId = :userId AND ars.alertId IN :alertIds")
    Set<Long> findReadAlertIdsByUserId(@Param("userId") Long userId, @Param("alertIds") Collection<Long> alertIds);

    @Modifying
    @Query(value = "INSERT INTO alert_read_status (alert_id, user_id, read_at) VALUES (:alertId, :userId, NOW()) ON CONFLICT DO NOTHING",
            nativeQuery = true)
    void insertOnConflictDoNothing(@Param("alertId") Long alertId, @Param("userId") Long userId);
}
