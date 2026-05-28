package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.TileRegionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataTileRegionRepository extends JpaRepository<TileRegionJpaEntity, Long> {
    Optional<TileRegionJpaEntity> findByName(String name);
    List<TileRegionJpaEntity> findByStatus(String status);

    @Query("SELECT r FROM TileRegionJpaEntity r WHERE r.minLon <= :maxLon AND r.maxLon >= :minLon AND r.minLat <= :maxLat AND r.maxLat >= :minLat")
    List<TileRegionJpaEntity> findIntersecting(@Param("minLon") double minLon, @Param("minLat") double minLat,
                                                @Param("maxLon") double maxLon, @Param("maxLat") double maxLat);
}
