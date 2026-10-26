package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.RumenMotilityLogJpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface RumenMotilityLogJpaRepository extends JpaRepository<RumenMotilityLogJpaEntity, Long> {
    List<RumenMotilityLogJpaEntity> findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(Long livestockId, Instant from, Instant to);
    List<RumenMotilityLogJpaEntity> findByLivestockIdOrderByRecordedAtDesc(Long livestockId);
    List<RumenMotilityLogJpaEntity> findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(
            Long deviceId, Instant from, Instant to);
    Page<RumenMotilityLogJpaEntity> findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(
            Long livestockId, Instant from, Instant to, Pageable pageable);
    Page<RumenMotilityLogJpaEntity> findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(
            Long deviceId, Instant from, Instant to, Pageable pageable);

    Optional<RumenMotilityLogJpaEntity> findFirstByDeviceIdAndRawCounterIsNotNullOrderByRecordedAtDesc(Long deviceId);
}
