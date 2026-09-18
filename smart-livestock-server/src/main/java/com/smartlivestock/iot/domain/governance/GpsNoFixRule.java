package com.smartlivestock.iot.domain.governance;

import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Optional;

/**
 * Flags (0,0) frames as "no fix" placeholders. Evidence: indoor device 166
 * reported (0,0) for its whole indoor period; the same device produced valid
 * fixes after moving outdoors, so no-fix is a dynamic state, not permanent.
 * Consumers (fence detection, trajectory, distance) must skip these frames.
 */
@Component
public class GpsNoFixRule implements TelemetryValidationRule {

    public static final String NAME = "gps_no_fix";

    @Override
    public String name() {
        return NAME;
    }

    @Override
    public Optional<String> validate(Map<String, Object> readings, TelemetrySource source, DeviceType deviceType) {
        Object latObj = readings.get("latitude");
        Object lngObj = readings.get("longitude");
        if (latObj == null || lngObj == null) {
            return Optional.empty();
        }
        BigDecimal latitude = toBigDecimal(latObj);
        BigDecimal longitude = toBigDecimal(lngObj);
        if (latitude != null && longitude != null
                && latitude.compareTo(BigDecimal.ZERO) == 0
                && longitude.compareTo(BigDecimal.ZERO) == 0) {
            return Optional.of("no-fix placeholder (0,0)");
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
