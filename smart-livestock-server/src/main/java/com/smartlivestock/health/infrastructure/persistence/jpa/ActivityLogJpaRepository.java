package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.ActivityLogJpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface ActivityLogJpaRepository extends JpaRepository<ActivityLogJpaEntity, Long> {
    List<ActivityLogJpaEntity> findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(Long livestockId, Instant from, Instant to);
    Page<ActivityLogJpaEntity> findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(Long livestockId, Instant from, Instant to, Pageable pageable);
    List<ActivityLogJpaEntity> findByLivestockIdOrderByRecordedAtDesc(Long livestockId);
}
