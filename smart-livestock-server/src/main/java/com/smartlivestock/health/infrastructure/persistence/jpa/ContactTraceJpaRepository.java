package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.ContactTraceJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ContactTraceJpaRepository extends JpaRepository<ContactTraceJpaEntity, Long> {
    List<ContactTraceJpaEntity> findByFarmIdOrderByLastContactAtDesc(Long farmId);
}
