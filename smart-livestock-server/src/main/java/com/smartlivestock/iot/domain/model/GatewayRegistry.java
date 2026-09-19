package com.smartlivestock.iot.domain.model;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Registered position of a LoRaWAN gateway (NIX-219). A gateway is a physical
 * entity with one position: gateway_id is globally unique and a later marker
 * overwrites the previous one (the UI confirms overwrites).
 */
@Getter
@Setter
public class GatewayRegistry {

    private Long id;
    private String gatewayId;
    private BigDecimal latitude;
    private BigDecimal longitude;

    /** User who marked the position last. */
    private Long markedBy;
    private Instant markedAt;

    /** APP / SEED / IMPORT. */
    private String source;

    private Instant createdAt;
    private Instant updatedAt;
}
