package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.TileDownloadLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataTileDownloadLogRepository extends JpaRepository<TileDownloadLogJpaEntity, Long> {
    List<TileDownloadLogJpaEntity> findByUserId(Long userId);
}
