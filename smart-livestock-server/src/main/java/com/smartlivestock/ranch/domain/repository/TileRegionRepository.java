package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.TileRegion;
import java.util.List;
import java.util.Optional;

public interface TileRegionRepository {
    TileRegion save(TileRegion region);
    Optional<TileRegion> findById(Long id);
    Optional<TileRegion> findByName(String name);
    List<TileRegion> findAll();
    List<TileRegion> findByStatus(String status);
    List<TileRegion> findIntersecting(double minLon, double minLat, double maxLon, double maxLat);
}
