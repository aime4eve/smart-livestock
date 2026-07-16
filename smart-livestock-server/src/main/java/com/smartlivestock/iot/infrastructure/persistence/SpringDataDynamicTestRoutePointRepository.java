package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DynamicTestRoutePointJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataDynamicTestRoutePointRepository extends JpaRepository<DynamicTestRoutePointJpaEntity, Long> {

    List<DynamicTestRoutePointJpaEntity> findByRouteIdOrderBySequenceNoAsc(Long routeId);

    void deleteByRouteId(Long routeId);
}
