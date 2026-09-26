package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.domain.model.EpidemicDispositionStatus;
import com.smartlivestock.health.infrastructure.persistence.entity.EpidemicDispositionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface EpidemicDispositionJpaRepository
        extends JpaRepository<EpidemicDispositionJpaEntity, Long> {

    List<EpidemicDispositionJpaEntity> findByFarmIdAndStatusIn(Long farmId, Collection<EpidemicDispositionStatus> statuses);

    Optional<EpidemicDispositionJpaEntity> findFirstByFarmIdAndLivestockIdAndStatusInOrderByUpdatedAtDesc(
            Long farmId, Long livestockId, Collection<EpidemicDispositionStatus> statuses);

    List<EpidemicDispositionJpaEntity> findBySourceLivestockIdAndStatusIn(
            Long sourceLivestockId, Collection<EpidemicDispositionStatus> statuses);
}
