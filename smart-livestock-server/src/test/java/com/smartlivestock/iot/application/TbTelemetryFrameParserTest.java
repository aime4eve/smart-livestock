package com.smartlivestock.iot.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.iot.domain.model.DeviceType;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class TbTelemetryFrameParserTest {

    private final ObjectMapper mapper = new ObjectMapper();

    private String resultValue(Map<String, Object> properties) throws Exception {
        return mapper.writeValueAsString(Map.of(
                "decodeStatus", true,
                "decodeData", Map.of("properties", properties)));
    }

    private String rawResult(String raw) {
        return raw;
    }

    @Test
    void shouldParseCapsuleResultFrameWithOcConverterKeys() throws Exception {
        String result = resultValue(Map.of(
                "temperatureGroup", List.of(38.5, 38.6),
                "gastricMotility", 987654,
                "batteryVoltage", 2950,
                "xAxisAccelerationValue", 100,
                "software", "1.2.3",
                "dataSyncCycle", 5));
        var node = mapper.readTree(mapper.writeValueAsString(Map.of(
                "result", List.of(Map.of("ts", 1000, "value", result)),
                "rssi", List.of(Map.of("ts", 1000, "value", -67)),
                "snr", List.of(Map.of("ts", 1000, "value", 9.5)),
                "downLinkGateway", List.of(Map.of("ts", 1000, "value", "gw-01")))));

        var frames = TbTelemetryFrameParser.extract(node, DeviceType.CAPSULE).frames();

        assertThat(frames).hasSize(1);
        var frame = frames.get(0);
        assertThat(frame.ts()).isEqualTo(1000L);
        assertThat(frame.readings().get("temperatures")).asList().hasSize(2);
        assertThat(frame.readings().get("gastricMotility")).isEqualTo(987654);
        assertThat(frame.readings().get("batteryVoltage")).isEqualTo(2950);
        assertThat(frame.readings().get("battery")).isEqualTo(75);
        assertThat(frame.readings().get("accelXRaw")).isEqualTo(100);
        assertThat(frame.readings().get("softwareVersion")).isEqualTo("1.2.3");
        assertThat(frame.readings().get("rssi")).isEqualTo(-67);
        assertThat(frame.readings().get("gatewayId")).isEqualTo("gw-01");
    }

    @Test
    void shouldSkipDataHexThatDuplicatesResultFrame() throws Exception {
        String result = resultValue(Map.of("battery", 80));
        String hex = "686B7405010332" + "4900002710";
        var node = mapper.readTree(mapper.writeValueAsString(Map.of(
                "result", List.of(Map.of("ts", 1000, "value", result)),
                "dataHex", List.of(Map.of("ts", 1800, "value", hex)))));

        var frames = TbTelemetryFrameParser.extract(node, DeviceType.CAPSULE).frames();

        assertThat(frames).hasSize(1);
        assertThat(frames.get(0).ts()).isEqualTo(1000L);
        assertThat(frames.get(0).readings().get("battery")).isEqualTo(80);
    }

    @Test
    void shouldFallbackToTlvDecodeForDistantDataHexOnly() throws Exception {
        String hex = "686B7405010332" + "4900002710";
        var node = mapper.readTree(mapper.writeValueAsString(Map.of(
                "dataHex", List.of(Map.of("ts", 900000, "value", hex)))));

        var frames = TbTelemetryFrameParser.extract(node, DeviceType.CAPSULE).frames();

        assertThat(frames).hasSize(1);
        assertThat(frames.get(0).readings().get("battery")).isEqualTo(50);
        assertThat(frames.get(0).readings().get("gastricMotility")).isEqualTo(10000L);
    }

    @Test
    void shouldFallbackToTlvWhenDecodeStatusIsFalse() throws Exception {
        String hex = "686B7405010332" + "4900002710";
        var node = mapper.readTree(mapper.writeValueAsString(Map.of(
                "result", List.of(Map.of("ts", 1000, "value",
                        "{\"decodeStatus\":false,\"decodeData\":{\"properties\":{\"battery\":80}}")),
                "dataHex", List.of(Map.of("ts", 1000, "value", hex)))));

        var frames = TbTelemetryFrameParser.extract(node, DeviceType.CAPSULE).frames();

        assertThat(frames).hasSize(1);
        assertThat(frames.get(0).readings().get("battery")).isEqualTo(50);
    }

    @Test
    void shouldFallbackToTlvWhenResultIsMalformedJson() throws Exception {
        String hex = "686B7405010332" + "4900002710";
        var node = mapper.readTree(mapper.writeValueAsString(Map.of(
                "result", List.of(Map.of("ts", 1000, "value", rawResult("{bad json"))),
                "dataHex", List.of(Map.of("ts", 1000, "value", hex)))));

        var frames = TbTelemetryFrameParser.extract(node, DeviceType.CAPSULE).frames();

        assertThat(frames).hasSize(1);
        assertThat(frames.get(0).readings().get("battery")).isEqualTo(50);
    }

    @Test
    void shouldFallbackToLegacyTlvWhenConverterReportsLegacyUnknownTypes() throws Exception {
        String legacyTemperatureHex = "686B74007C01100A45050B030AFA0AF80AEE0B02"
                + "8BEE49000099974A684B624CD886000F";
        String legacyMotilityHex = "686B74007C01100A4D050B030AFA0AF80AEE0B02"
                + "8B0BF924000099974A684B624CD886000F";
        var node = mapper.readTree(mapper.writeValueAsString(Map.of(
                "result", List.of(
                        Map.of("ts", 1000, "value",
                                "{\"sync_header\":\"68 6B 74\",\"unknown_type\":69}"),
                        Map.of("ts", 2000, "value",
                                "{\"sync_header\":\"68 6B 74\",\"unknown_type\":36}")),
                "dataHex", List.of(
                        Map.of("ts", 1000, "value", legacyTemperatureHex),
                        Map.of("ts", 2000, "value", legacyMotilityHex)))));

        var parsed = TbTelemetryFrameParser.extract(node, DeviceType.CAPSULE);
        var frames = parsed.frames();

        assertThat(parsed.skippedTs()).isEmpty();
        assertThat(frames).hasSize(2);
        assertThat(frames.get(0).readings().get("temperatures")).asList().hasSize(5);
        assertThat(frames.get(0).readings().get("gastricMotility")).isEqualTo(39319L);
        assertThat(frames.get(1).readings().get("batteryVoltage")).isEqualTo(3065);
        assertThat(frames.get(1).readings().get("gastricMotility")).isEqualTo(39319L);
    }

    @Test
    void shouldSkipInvalidTrackerResultWithoutFallback() throws Exception {
        var node = mapper.readTree(mapper.writeValueAsString(Map.of(
                "result", List.of(Map.of("ts", 1000, "value",
                        "{\"decodeStatus\":false,\"decodeData\":{\"properties\":{\"battery\":80}}")))));

        var parsed = TbTelemetryFrameParser.extract(node, DeviceType.TRACKER);

        assertThat(parsed.frames()).isEmpty();
        assertThat(parsed.skippedTs()).containsExactly(1000L);
    }

    @Test
    void shouldMapTrackerPropertiesAndSortByTs() throws Exception {
        String newer = resultValue(Map.of(
                "latitude", 28.24, "longitude", 112.85,
                "stepNumber", 42,
                "xAxisDirectionAccelerationValue", 100,
                "battery", 66));
        String older = resultValue(Map.of("battery", 65));
        var node = mapper.readTree(mapper.writeValueAsString(Map.of(
                "result", List.of(
                        Map.of("ts", 3000, "value", newer),
                        Map.of("ts", 2000, "value", older)))));

        var frames = TbTelemetryFrameParser.extract(node, DeviceType.TRACKER).frames();

        assertThat(frames).hasSize(2);
        assertThat(frames.get(0).ts()).isEqualTo(2000L);
        assertThat(frames.get(1).readings().get("stepNumber")).isEqualTo(42);
        assertThat(frames.get(1).readings().get("accelXRaw")).isEqualTo(100);
    }
}
