package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.domain.model.DatagenFarmControl;
import com.smartlivestock.datagen.domain.repository.DatagenFarmControlRepository;
import com.smartlivestock.datagen.infrastructure.persistence.entity.DatagenFarmControlJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.mapper.DatagenControlMapper;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDatagenFarmControlRepositoryImpl implements DatagenFarmControlRepository {
    private final DatagenFarmControlJpaRepository jpaRepository;

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    public DatagenFarmControl save(DatagenFarmControl control) {
        DatagenFarmControlJpaEntity existing = control.getId() == null
                ? null : jpaRepository.findById(control.getId()).orElse(null);
        DatagenFarmControlJpaEntity entity =
                DatagenControlMapper.toEntity(control, existing);
        return DatagenControlMapper.toDomain(jpaRepository.save(entity));
    }

    @Override
    public Optional<DatagenFarmControl> findById(Long id) {
        return jpaRepository.findById(id).map(DatagenControlMapper::toDomain);
    }

    @Override
    public Optional<DatagenFarmControl> findByFarmId(Long farmId) {
        return jpaRepository.findByFarmId(farmId).map(DatagenControlMapper::toDomain);
    }

    @Override
    public Optional<DatagenFarmControl> lockByFarmId(Long farmId) {
        return jpaRepository.findByFarmIdForUpdate(farmId)
                .map(DatagenControlMapper::toDomain);
    }

    @Override
    public DatagenFarmControl ensureByFarmId(Long tenantId, Long farmId, Long scenarioId) {
        entityManager.createNativeQuery("""
                INSERT INTO datagen_farm_controls
                    (tenant_id, farm_id, scenario_id, enabled)
                VALUES (:tenantId, :farmId, :scenarioId, false)
                ON CONFLICT (farm_id) DO NOTHING
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("farmId", farmId)
                .setParameter("scenarioId", scenarioId)
                .executeUpdate();
        return lockByFarmId(farmId).orElseThrow();
    }

    @Override
    public List<DatagenFarmControl> findByTenantId(Long tenantId) {
        return jpaRepository.findByTenantId(tenantId).stream()
                .map(DatagenControlMapper::toDomain)
                .toList();
    }

    @Override
    public List<DatagenFarmControl> findAll() {
        return jpaRepository.findAll().stream()
                .map(DatagenControlMapper::toDomain)
                .toList();
    }
}
