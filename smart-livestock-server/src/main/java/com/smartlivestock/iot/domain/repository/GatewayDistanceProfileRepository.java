package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GatewayDistanceProfileRow;

import java.util.List;

public interface GatewayDistanceProfileRepository {

    /** Atomically replace all bucket rows of one gateway. */
    void replaceAll(String gatewayId, List<GatewayDistanceProfileRow> rows, int windowDays);

    List<GatewayDistanceProfileRow> findByGatewayId(String gatewayId);

    /** Gateways that currently have a profile. */
    List<String> findGatewaysWithProfile();
}
