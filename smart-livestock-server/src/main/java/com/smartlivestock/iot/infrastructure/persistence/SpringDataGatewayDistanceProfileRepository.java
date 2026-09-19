package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GatewayDistanceProfileJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataGatewayDistanceProfileRepository
        extends JpaRepository<GatewayDistanceProfileJpaEntity, Long> {

    List<GatewayDistanceProfileJpaEntity> findByGatewayIdOrderByBucketRssi(String gatewayId);

    void deleteByGatewayId(String gatewayId);
}
