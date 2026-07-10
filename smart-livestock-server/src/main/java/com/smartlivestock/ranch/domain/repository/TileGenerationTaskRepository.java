package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.TileGenerationTask;
import java.util.List;
import java.util.Optional;

public interface TileGenerationTaskRepository {
    TileGenerationTask save(TileGenerationTask task);
    Optional<TileGenerationTask> findById(Long id);
    List<TileGenerationTask> findByStatus(String status);
    List<TileGenerationTask> findAll();
}
