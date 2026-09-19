package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GatewayRegistryJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SpringDataGatewayRegistryRepository extends JpaRepository<GatewayRegistryJpaEntity, Long> {

    Optional<GatewayRegistryJpaEntity> findByGatewayId(String gatewayId);
}
