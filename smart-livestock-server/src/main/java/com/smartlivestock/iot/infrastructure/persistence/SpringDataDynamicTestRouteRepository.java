package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DynamicTestRouteJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataDynamicTestRouteRepository extends JpaRepository<DynamicTestRouteJpaEntity, Long> {
}
