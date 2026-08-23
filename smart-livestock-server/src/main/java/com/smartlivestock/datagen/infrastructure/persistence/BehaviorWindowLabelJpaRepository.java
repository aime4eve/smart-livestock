package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowLabelJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface BehaviorWindowLabelJpaRepository
        extends JpaRepository<BehaviorWindowLabelJpaEntity, Long> {
    List<BehaviorWindowLabelJpaEntity> findByWindowIdIn(Collection<UUID> windowIds);
}
