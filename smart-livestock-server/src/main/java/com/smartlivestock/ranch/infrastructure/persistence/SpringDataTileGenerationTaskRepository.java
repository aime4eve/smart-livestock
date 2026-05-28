package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.TileGenerationTaskJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataTileGenerationTaskRepository extends JpaRepository<TileGenerationTaskJpaEntity, Long> {
    List<TileGenerationTaskJpaEntity> findByStatus(String status);
}
