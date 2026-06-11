package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.FenceZoneJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataFenceZoneRepository extends JpaRepository<FenceZoneJpaEntity, Long> {
    List<FenceZoneJpaEntity> findByFarmId(Long farmId);
}
