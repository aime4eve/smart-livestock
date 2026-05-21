package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.LivestockJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataLivestockRepository extends JpaRepository<LivestockJpaEntity, Long> {
    List<LivestockJpaEntity> findByFarmId(Long farmId);
    Optional<LivestockJpaEntity> findByLivestockCode(String livestockCode);
    long countByFarmId(Long farmId);
}
