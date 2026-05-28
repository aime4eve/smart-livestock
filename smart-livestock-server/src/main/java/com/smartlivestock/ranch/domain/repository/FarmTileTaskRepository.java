package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.FarmTileTask;
import java.util.List;
import java.util.Optional;

public interface FarmTileTaskRepository {
    FarmTileTask save(FarmTileTask task);
    Optional<FarmTileTask> findById(Long id);
    List<FarmTileTask> findByFarmId(Long farmId);
    Optional<FarmTileTask> findByFarmIdAndRegionId(Long farmId, Long regionId);
    List<FarmTileTask> findAll();
}
