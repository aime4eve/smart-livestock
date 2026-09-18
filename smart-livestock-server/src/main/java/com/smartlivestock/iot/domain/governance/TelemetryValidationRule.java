package com.smartlivestock.iot.domain.governance;

import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TelemetrySource;

import java.util.Map;
import java.util.Optional;

/**
 * A single data-governance validation rule (NIX-220).
 * Rules are registered as Spring beans; GPS validity is the first rule set,
 * rumen-capsule rule sets join later. Rules flag, they never delete: raw
 * frames are always persisted (gps_logs full-retention principle, NIX-9 spec 6.4).
 */
public interface TelemetryValidationRule {

    String name();

    /**
     * @return flag reason when the frame violates the rule, empty when it passes
     *         or does not apply (e.g. no GPS keys on a capsule frame).
     */
    Optional<String> validate(Map<String, Object> readings, TelemetrySource source, DeviceType deviceType);
}
