package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.FenceJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataFenceRepository extends JpaRepository<FenceJpaEntity, Long> {
    List<FenceJpaEntity> findByFarmId(Long farmId);
    long countByFarmId(Long farmId);
}
