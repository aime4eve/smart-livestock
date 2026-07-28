package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityLineResultJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataGpsQualityLineResultRepository
        extends JpaRepository<GpsQualityLineResultJpaEntity, Long> {
}
