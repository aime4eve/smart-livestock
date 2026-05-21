package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.Fence;

import java.util.List;
import java.util.Optional;

public interface FenceRepository {
    Fence save(Fence fence);
    Optional<Fence> findById(Long id);
    List<Fence> findByFarmId(Long farmId);
    void deleteById(Long id);
    long countByFarmId(Long farmId);
}
