package com.smartlivestock.iot.domain.governance;

import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class GovernanceRulesTest {

    private final GpsCoordRangeRule rangeRule = new GpsCoordRangeRule();
    private final GpsNoFixRule noFixRule = new GpsNoFixRule();
    private final GatewayMissingRule gatewayRule = new GatewayMissingRule();

    @Test
    void longitudeBeyond180_isFlagged() {
        Optional<String> flagged = rangeRule.validate(
                Map.of("latitude", 28.24, "longitude", 842.06697),
                TelemetrySource.THINGSBOARD, DeviceType.TRACKER);
        assertThat(flagged).contains("longitude out of range: 842.06697");
    }

    @Test
    void validCoordinates_pass() {
        assertThat(rangeRule.validate(Map.of("latitude", 28.2465, "longitude", 112.8513),
                TelemetrySource.THINGSBOARD, DeviceType.TRACKER)).isEmpty();
    }

    @Test
    void zeroZero_isNoFix() {
        assertThat(noFixRule.validate(Map.of("latitude", 0, "longitude", 0),
                TelemetrySource.AGENTIC_PLATFORM, DeviceType.TRACKER)).isPresent();
    }

    @Test
    void missingGateway_isFlagged_butDatagenSkipped() {
        assertThat(gatewayRule.validate(Map.of("latitude", 28.2),
                TelemetrySource.THINGSBOARD, DeviceType.TRACKER)).isPresent();
        assertThat(gatewayRule.validate(Map.of("latitude", 28.2),
                TelemetrySource.DATAGEN, DeviceType.TRACKER)).isEmpty();
        assertThat(gatewayRule.validate(Map.of("gatewayId", "b83b8fffff000183"),
                TelemetrySource.THINGSBOARD, DeviceType.TRACKER)).isEmpty();
    }

    @Test
    void framesWithoutGpsKeys_passQuietly() {
        assertThat(rangeRule.validate(Map.of("battery", 88),
                TelemetrySource.THINGSBOARD, DeviceType.CAPSULE)).isEmpty();
        assertThat(noFixRule.validate(Map.of("battery", 88),
                TelemetrySource.THINGSBOARD, DeviceType.CAPSULE)).isEmpty();
    }
}
