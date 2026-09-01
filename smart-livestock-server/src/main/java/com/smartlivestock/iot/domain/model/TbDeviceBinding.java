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
    /** Last cycle that attempted this device, successful or not. */
    private Instant lastPollAt;
    /** Consecutive page/API/ingest failures; reset on a clean cycle. */
    private int consecutiveFailures;

    /**
     * TB-channel health gate for the blade fallback: blade polling stays
     * excluded for a bound device only while the TB channel looks healthy.
     * A frozen cursor (rule chain stopped saving decodable timeseries) or
     * repeated failures degrade the device back to the blade channel. A
     * binding that has never been polled gets the benefit of the doubt until
     * its first stale window elapses after the first poll.
     */
    public boolean isTbChannelHealthy(long nowMs, long staleAfterMs, int failureThreshold) {
        if (consecutiveFailures >= failureThreshold) return false;
        Long baseline = telemetryCursorMs != null ? telemetryCursorMs
                : lastPollAt != null ? lastPollAt.toEpochMilli() : null;
        return baseline == null || nowMs - baseline <= staleAfterMs;
    }
}
