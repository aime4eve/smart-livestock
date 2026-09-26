package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.LivestockLocationSnapshotJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LivestockLocationSnapshotJpaRepository
        extends JpaRepository<LivestockLocationSnapshotJpaEntity, Long> {

    Optional<LivestockLocationSnapshotJpaEntity> findByLivestockId(Long livestockId);

    List<LivestockLocationSnapshotJpaEntity> findByFarmId(Long farmId);

    List<LivestockLocationSnapshotJpaEntity> findByFarmIdAndPositionRevisionGreaterThan(
            Long farmId, Long positionRevision);
}
