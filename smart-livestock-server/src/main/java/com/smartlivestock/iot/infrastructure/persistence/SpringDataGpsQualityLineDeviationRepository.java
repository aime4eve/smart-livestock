package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityLineDeviationJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataGpsQualityLineDeviationRepository
        extends JpaRepository<GpsQualityLineDeviationJpaEntity, Long> {

    List<GpsQualityLineDeviationJpaEntity> findByTestIdOrderBySequenceNo(Long testId);

    void deleteByTestId(Long testId);
}
