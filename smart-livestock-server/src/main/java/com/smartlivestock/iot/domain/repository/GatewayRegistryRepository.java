package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GatewayRegistry;

import java.util.List;
import java.util.Optional;

public interface GatewayRegistryRepository {

    GatewayRegistry save(GatewayRegistry registry);

    Optional<GatewayRegistry> findByGatewayId(String gatewayId);

    List<GatewayRegistry> findAll();

    long count();
}
