package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityTrackPointJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataGpsQualityTrackPointRepository
        extends JpaRepository<GpsQualityTrackPointJpaEntity, Long> {

    List<GpsQualityTrackPointJpaEntity> findByTestIdOrderByCollectedAt(Long testId);

    void deleteByTestId(Long testId);
}
