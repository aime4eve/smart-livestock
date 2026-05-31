package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.RumenMotilityLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface RumenMotilityLogJpaRepository extends JpaRepository<RumenMotilityLogJpaEntity, Long> {
    List<RumenMotilityLogJpaEntity> findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(Long livestockId, Instant from, Instant to);
    List<RumenMotilityLogJpaEntity> findByLivestockIdOrderByRecordedAtDesc(Long livestockId);
}
