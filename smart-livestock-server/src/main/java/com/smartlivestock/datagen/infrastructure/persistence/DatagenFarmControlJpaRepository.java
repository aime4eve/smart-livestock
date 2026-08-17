package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.DatagenFarmControlJpaEntity;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface DatagenFarmControlJpaRepository
        extends JpaRepository<DatagenFarmControlJpaEntity, Long> {
    Optional<DatagenFarmControlJpaEntity> findByFarmId(Long farmId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM DatagenFarmControlJpaEntity c WHERE c.farmId = :farmId")
    Optional<DatagenFarmControlJpaEntity> findByFarmIdForUpdate(@Param("farmId") Long farmId);

    List<DatagenFarmControlJpaEntity> findByTenantId(Long tenantId);
}
