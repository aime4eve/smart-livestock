package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityLineDeviationJpaEntity;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SpringDataGpsQualityLineDeviationRepository
        extends JpaRepository<GpsQualityLineDeviationJpaEntity, Long> {

    List<GpsQualityLineDeviationJpaEntity> findByTestIdOrderBySequenceNo(Long testId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM GpsQualityLineDeviationJpaEntity d WHERE d.testId = :testId")
    void deleteByTestId(@Param("testId") Long testId);
}
