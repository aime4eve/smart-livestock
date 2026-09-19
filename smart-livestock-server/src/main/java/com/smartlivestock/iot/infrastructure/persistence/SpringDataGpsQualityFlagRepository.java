package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityFlagJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

interface SpringDataGpsQualityFlagRepository extends JpaRepository<GpsQualityFlagJpaEntity, Long> {

    Optional<GpsQualityFlagJpaEntity> findByDeviceIdAndRuleNameAndFlagDay(
            Long deviceId, String ruleName, LocalDate flagDay);

    @Query("""
            SELECT f.ruleName, f.flagDay, SUM(f.flagCount), COUNT(DISTINCT f.deviceId)
            FROM GpsQualityFlagJpaEntity f
            WHERE f.updatedAt >= :from AND f.updatedAt < :to
            GROUP BY f.ruleName, f.flagDay
            ORDER BY f.flagDay DESC, f.ruleName
            """)
    List<Object[]> summarizeRowsByRuleAndDay(@Param("from") Instant from, @Param("to") Instant to);

    @Query("""
            SELECT f.deviceId, f.ruleName, SUM(f.flagCount)
            FROM GpsQualityFlagJpaEntity f
            WHERE f.updatedAt >= :from AND f.updatedAt < :to
            GROUP BY f.deviceId, f.ruleName
            ORDER BY SUM(f.flagCount) DESC
            """)
    List<Object[]> summarizeRowsByDevice(@Param("from") Instant from, @Param("to") Instant to);
}
