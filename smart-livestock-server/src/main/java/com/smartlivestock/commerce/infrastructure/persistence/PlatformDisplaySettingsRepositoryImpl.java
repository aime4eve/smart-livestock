package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.domain.model.LockedTilePolicy;
import com.smartlivestock.commerce.domain.model.PlatformDisplaySettings;
import com.smartlivestock.commerce.domain.repository.PlatformDisplaySettingsRepository;
import com.smartlivestock.commerce.infrastructure.persistence.entity.PlatformDisplaySettingsJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class PlatformDisplaySettingsRepositoryImpl implements PlatformDisplaySettingsRepository {

    private final SpringDataPlatformDisplaySettingsRepository jpaRepo;

    @Override
    public Optional<PlatformDisplaySettings> findFirst() {
        return jpaRepo.findFirstByOrderByIdAsc().map(PlatformDisplaySettingsRepositoryImpl::toDomain);
    }

    @Override
    public PlatformDisplaySettings save(PlatformDisplaySettings settings) {
        // Upsert semantics for the single-row table: reuse the existing row so
        // the id/created state survives, insert only when the seed row is gone.
        PlatformDisplaySettingsJpaEntity entity = jpaRepo.findFirstByOrderByIdAsc()
                .orElseGet(PlatformDisplaySettingsJpaEntity::new);
        entity.setLockedTilePolicy(settings.getLockedTilePolicy().name());
        entity.setUpdatedBy(settings.getUpdatedBy());
        return toDomain(jpaRepo.save(entity));
    }

    private static PlatformDisplaySettings toDomain(PlatformDisplaySettingsJpaEntity entity) {
        return new PlatformDisplaySettings(
                entity.getId(),
                LockedTilePolicy.fromString(entity.getLockedTilePolicy()),
                entity.getUpdatedAt(),
                entity.getUpdatedBy());
    }
}
