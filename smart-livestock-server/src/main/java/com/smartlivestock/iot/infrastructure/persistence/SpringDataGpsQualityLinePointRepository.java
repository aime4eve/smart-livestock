package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityLinePointJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataGpsQualityLinePointRepository
        extends JpaRepository<GpsQualityLinePointJpaEntity, Long> {

    List<GpsQualityLinePointJpaEntity> findByTestIdOrderBySequenceNo(Long testId);

    void deleteByTestId(Long testId);
}
