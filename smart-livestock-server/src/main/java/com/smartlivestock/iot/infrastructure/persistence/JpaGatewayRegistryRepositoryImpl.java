package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GatewayRegistry;
import com.smartlivestock.iot.domain.repository.GatewayRegistryRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GatewayRegistryJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaGatewayRegistryRepositoryImpl implements GatewayRegistryRepository {

    private final SpringDataGatewayRegistryRepository springData;

    @Override
    public GatewayRegistry save(GatewayRegistry registry) {
        GatewayRegistryJpaEntity entity = springData.findByGatewayId(registry.getGatewayId())
                .orElseGet(GatewayRegistryJpaEntity::new);
        entity.setGatewayId(registry.getGatewayId());
        entity.setLatitude(registry.getLatitude());
        entity.setLongitude(registry.getLongitude());
        entity.setMarkedBy(registry.getMarkedBy());
        entity.setMarkedAt(registry.getMarkedAt() != null ? registry.getMarkedAt() : entity.getMarkedAt());
        entity.setSource(registry.getSource() != null ? registry.getSource() : entity.getSource());
        entity.setUpdatedAt(java.time.Instant.now());
        return toDomain(springData.save(entity));
    }

    @Override
    public Optional<GatewayRegistry> findByGatewayId(String gatewayId) {
        return springData.findByGatewayId(gatewayId).map(this::toDomain);
    }

    @Override
    public List<GatewayRegistry> findAll() {
        return springData.findAll().stream().map(this::toDomain).toList();
    }

    @Override
    public long count() {
        return springData.count();
    }

    private GatewayRegistry toDomain(GatewayRegistryJpaEntity e) {
        GatewayRegistry r = new GatewayRegistry();
        r.setId(e.getId());
        r.setGatewayId(e.getGatewayId());
        r.setLatitude(e.getLatitude());
        r.setLongitude(e.getLongitude());
        r.setMarkedBy(e.getMarkedBy());
        r.setMarkedAt(e.getMarkedAt());
        r.setSource(e.getSource());
        r.setCreatedAt(e.getCreatedAt());
        r.setUpdatedAt(e.getUpdatedAt());
        return r;
    }
}
