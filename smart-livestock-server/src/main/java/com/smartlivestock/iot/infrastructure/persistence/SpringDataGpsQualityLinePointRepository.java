package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityLinePointJpaEntity;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SpringDataGpsQualityLinePointRepository
        extends JpaRepository<GpsQualityLinePointJpaEntity, Long> {

    List<GpsQualityLinePointJpaEntity> findByTestIdOrderBySequenceNo(Long testId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM GpsQualityLinePointJpaEntity p WHERE p.testId = :testId")
    void deleteByTestId(@Param("testId") Long testId);
}
