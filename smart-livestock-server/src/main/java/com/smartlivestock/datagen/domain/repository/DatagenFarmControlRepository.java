package com.smartlivestock.datagen.domain.repository;

import com.smartlivestock.datagen.domain.model.DatagenFarmControl;

import java.util.List;
import java.util.Optional;

public interface DatagenFarmControlRepository {
    DatagenFarmControl save(DatagenFarmControl control);
    Optional<DatagenFarmControl> findById(Long id);
    Optional<DatagenFarmControl> findByFarmId(Long farmId);
    Optional<DatagenFarmControl> lockByFarmId(Long farmId);
    DatagenFarmControl ensureByFarmId(Long tenantId, Long farmId, Long scenarioId);
    List<DatagenFarmControl> findByTenantId(Long tenantId);
    List<DatagenFarmControl> findAll();
}
