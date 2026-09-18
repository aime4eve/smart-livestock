package com.smartlivestock.iot.domain.governance;

import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Optional;

/**
 * Flags coordinates outside the valid ranges (lat [-90,90], lng [-180,180]).
 * Real-world evidence: device 194 reported lng=842.06697, device 175 lng=897.88364
 * (test DB, 2026-09-18) — suspected device-side encoding/unit defect.
 */
@Component
public class GpsCoordRangeRule implements TelemetryValidationRule {

    public static final String NAME = "gps_coord_range";

    @Override
    public String name() {
        return NAME;
    }

    @Override
    public Optional<String> validate(Map<String, Object> readings, TelemetrySource source, DeviceType deviceType) {
        BigDecimal latitude = toBigDecimal(readings.get("latitude"));
        BigDecimal longitude = toBigDecimal(readings.get("longitude"));
        if (latitude == null && longitude == null) {
            return Optional.empty();
        }
        if (latitude != null && latitude.abs().compareTo(BigDecimal.valueOf(90)) > 0) {
            return Optional.of("latitude out of range: " + latitude);
        }
        if (longitude != null && longitude.abs().compareTo(BigDecimal.valueOf(180)) > 0) {
            return Optional.of("longitude out of range: " + longitude);
        }
        return Optional.empty();
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof BigDecimal bd) return bd;
        if (value instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        try {
            return new BigDecimal(value.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
