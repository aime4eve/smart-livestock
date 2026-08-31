package com.smartlivestock.iot.domain.model;

import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Binding between a local device and an external platform device identity.
 * Phase 1 only uses provider THINGSBOARD; the provider column keeps the
 * model extensible for future multi-provider routing (parking NIX-80 D11).
 */
@Getter
@Setter
public class TbDeviceBinding {

    public static final String PROVIDER_THINGSBOARD = "THINGSBOARD";

    public enum Status { PENDING, RESOLVED, INVALID }

    private Long id;
    private Long tenantId;
    private Long deviceId;
    private String provider;
    private String deviceEui;
    private String externalDeviceId;
    private String externalDeviceName;
    private Status status;
    /** Fully-processed source time boundary (epoch ms); null = never pulled. */
    private Long telemetryCursorMs;
    private Instant lastEventAt;
    private Instant lastVerifiedAt;
}
