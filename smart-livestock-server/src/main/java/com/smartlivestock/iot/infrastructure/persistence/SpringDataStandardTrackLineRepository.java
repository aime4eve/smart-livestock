package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.StandardTrackLineJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataStandardTrackLineRepository
        extends JpaRepository<StandardTrackLineJpaEntity, Long> {

    List<StandardTrackLineJpaEntity> findByTenantIdOrderByCreatedAtDesc(Long tenantId);
}
