package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityTestJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;

public interface SpringDataGpsQualityTestRepository extends JpaRepository<GpsQualityTestJpaEntity, Long>,
        JpaSpecificationExecutor<GpsQualityTestJpaEntity> {

    List<GpsQualityTestJpaEntity> findBySessionId(Long sessionId);
    List<GpsQualityTestJpaEntity> findByRtkPointId(Long rtkPointId);
}
