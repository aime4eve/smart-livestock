package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.FenceZone;

import java.util.List;
import java.util.Optional;

public interface FenceZoneRepository {
    FenceZone save(FenceZone fenceZone);
    Optional<FenceZone> findById(Long id);
    List<FenceZone> findByFarmId(Long farmId);

    /**
     * Deletes all zones belonging to the given fence (zones have no meaning
     * without their parent fence).
     *
     * @return number of zones removed
     */
    int deleteByFenceId(Long fenceId);
}
