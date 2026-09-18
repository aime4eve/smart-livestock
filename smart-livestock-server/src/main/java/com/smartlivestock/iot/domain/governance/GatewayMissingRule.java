package com.smartlivestock.iot.domain.governance;

import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Optional;

/**
 * Flags frames without a usable gateway id (blank/null). Evidence: 3020 such
 * frames in device_telemetry_logs (test DB) cannot be attributed to a gateway,
 * which blocks per-gateway statistics such as communication distance.
 * DATAGEN frames are skipped: synthetic data must not pollute quality metrics.
 */
@Component
public class GatewayMissingRule implements TelemetryValidationRule {

    public static final String NAME = "gateway_missing";

    @Override
    public String name() {
        return NAME;
    }

    @Override
    public Optional<String> validate(Map<String, Object> readings, TelemetrySource source, DeviceType deviceType) {
        if (source == TelemetrySource.DATAGEN) {
            return Optional.empty();
        }
        Object gateway = readings.get("gatewayId");
        if (gateway == null || gateway.toString().isBlank()) {
            return Optional.of("gatewayId missing/blank");
        }
        return Optional.empty();
    }
}
