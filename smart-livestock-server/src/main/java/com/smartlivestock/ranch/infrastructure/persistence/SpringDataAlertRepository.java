package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.AlertJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataAlertRepository extends JpaRepository<AlertJpaEntity, Long> {
    List<AlertJpaEntity> findByFarmId(Long farmId);
    List<AlertJpaEntity> findByFarmIdAndStatus(Long farmId, String status);
}
