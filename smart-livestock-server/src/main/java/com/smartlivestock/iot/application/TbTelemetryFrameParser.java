package com.smartlivestock.iot.application;

import com.fasterxml.jackson.databind.JsonNode;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.service.RumenPayloadDecoder;
import lombok.extern.slf4j.Slf4j;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Parses ThingsBoard timeseries responses into per-frame readings.
 * <p>
 * Same-frame rule (parking NIX-80): result and dataHex are two keys of one
 * physical frame. result frames are authoritative; a dataHex point within
 * 2s of a result frame is the same frame and is skipped. A dataHex point
 * further away is a result-less frame and gets the TLV fallback decode.
 * <p>
 * Fault tolerance (NIX-179): frames that cannot be decoded under any path
 * (e.g. a modified TB rule chain saving {@code decodeStatus:false} results)
 * are reported as skipped instead of failing the whole page — the channel
 * advances its cursor past them so a handful of bad frames can never stall
 * the device permanently.
 */
@Slf4j
public final class TbTelemetryFrameParser {

    private static final long SAME_FRAME_WINDOW_MS = 2000;

    private TbTelemetryFrameParser() {}

    public record Frame(long ts, Map<String, Object> readings) {}

    /** Parsed page: decodable frames plus the timestamps of dropped ones. */
    public record ParseResult(List<Frame> frames, List<Long> skippedTs) {}

    public static ParseResult extract(JsonNode timeseries, DeviceType deviceType) {
        TreeMap<Long, Map<String, Object>> resultFrames = new TreeMap<>();
        TreeMap<Long, String> hexFrames = new TreeMap<>();
        TreeMap<Long, String> invalidFrames = new TreeMap<>();
        Map<Long, Map<String, Object>> transport = new HashMap<>();

        collectPoints(timeseries, "result", (ts, value) -> {
            Map<String, Object> readings = parseResultProperties(value);
            if (readings == null || readings.isEmpty()) {
                invalidFrames.put(ts, value.asText());
            } else {
                resultFrames.put(ts, readings);
            }
        });
        collectPoints(timeseries, "dataHex", (ts, value) ->
                hexFrames.put(ts, value.asText()));
        collectPoints(timeseries, "rssi", (ts, value) ->
                transport.computeIfAbsent(ts, k -> new HashMap<>()).put("rssi", value.asInt()));
        collectPoints(timeseries, "snr", (ts, value) ->
                transport.computeIfAbsent(ts, k -> new HashMap<>()).put("snr", value.asInt()));
        collectPoints(timeseries, "downLinkGateway", (ts, value) ->
                transport.computeIfAbsent(ts, k -> new HashMap<>()).put("gatewayId", value.asText()));

        List<Frame> frames = new ArrayList<>();
        for (Map.Entry<Long, Map<String, Object>> entry : resultFrames.entrySet()) {
            Map<String, Object> readings = new HashMap<>(entry.getValue());
            readings.putAll(transport.getOrDefault(entry.getKey(), Map.of()));
            frames.add(new Frame(entry.getKey(), readings));
        }
        for (Map.Entry<Long, String> entry : hexFrames.entrySet()) {
            if (hasResultFrameNearby(resultFrames, entry.getKey())) {
                continue;
            }
            Map<String, Object> readings = decodeHexFallback(entry.getValue(), deviceType);
            if (readings == null) {
                invalidFrames.put(entry.getKey(), entry.getValue());
                continue;
            }
            removeInvalidResultNearby(invalidFrames, entry.getKey());
            readings.putAll(transport.getOrDefault(entry.getKey(), Map.of()));
            frames.add(new Frame(entry.getKey(), readings));
        }
        if (!invalidFrames.isEmpty()) {
            log.warn("[TB] {} undecodable frame(s) skipped at timestamps {}",
                    invalidFrames.size(), invalidFrames.keySet());
        }
        frames.sort(Comparator.comparingLong(Frame::ts));
        return new ParseResult(List.copyOf(frames), List.copyOf(invalidFrames.keySet()));
    }

    private static void removeInvalidResultNearby(TreeMap<Long, String> invalidFrames, long ts) {
        Long floor = invalidFrames.floorKey(ts);
        if (floor != null && ts - floor <= SAME_FRAME_WINDOW_MS) {
            invalidFrames.remove(floor);
            return;
        }
        Long ceiling = invalidFrames.ceilingKey(ts);
        if (ceiling != null && ceiling - ts <= SAME_FRAME_WINDOW_MS) {
            invalidFrames.remove(ceiling);
        }
    }

    private static boolean hasResultFrameNearby(TreeMap<Long, Map<String, Object>> resultFrames, long ts) {
        Long floor = resultFrames.floorKey(ts);
        if (floor != null && ts - floor <= SAME_FRAME_WINDOW_MS) return true;
        Long ceiling = resultFrames.ceilingKey(ts);
        return ceiling != null && ceiling - ts <= SAME_FRAME_WINDOW_MS;
    }

    private static Map<String, Object> parseResultProperties(JsonNode resultValue) {
        JsonNode decoded;
        if (resultValue.isTextual()) {
            try {
                decoded = new com.fasterxml.jackson.databind.ObjectMapper().readTree(resultValue.asText());
            } catch (Exception e) {
                log.warn("[TB] result is not valid JSON: {}", e.getMessage());
                return null;
            }
        } else {
            decoded = resultValue;
        }
        if (!decoded.path("decodeStatus").asBoolean(false)) {
            return null;
        }
        JsonNode props = decoded.path("decodeData").path("properties");
        Map<String, Object> readings = new LinkedHashMap<>();
        copyDecimal(readings, props, "latitude");
        copyDecimal(readings, props, "longitude");
        copyInt(readings, props, "stepNumber", "stepNumber");
        copyInt(readings, props, "battery", "battery");
        copyInt(readings, props, "workMode", "workMode");
        copyInt(readings, props, "antiDisassemblyStatus", "antiDisassemblyStatus");
        // Tracker accel uses blade-compatible keys; capsule accel uses the OC
        // converter's shorter keys. Map both, first present wins.
        copyInt(readings, props, "xAxisDirectionAccelerationValue", "accelXRaw");
        copyInt(readings, props, "yAxisDirectionAccelerationValue", "accelYRaw");
        copyInt(readings, props, "zAxisDirectionAccelerationValue", "accelZRaw");
        copyInt(readings, props, "xAxisAccelerationValue", "accelXRaw");
        copyInt(readings, props, "yAxisAccelerationValue", "accelYRaw");
        copyInt(readings, props, "zAxisAccelerationValue", "accelZRaw");
        copyText(readings, props, "software", "softwareVersion");
        copyText(readings, props, "hardware", "hardwareVersion");
        copyInt(readings, props, "dataSyncCycle", "dataSyncCycle");
        copyInt(readings, props, "batteryVoltage", "batteryVoltage");
        if (readings.containsKey("batteryVoltage") && !readings.containsKey("battery")) {
            readings.put("battery", com.smartlivestock.iot.domain.service.DecodedRumenFrame
                    .batteryPercent((int) readings.get("batteryVoltage")));
        }
        copyInt(readings, props, "gastricMotility", "gastricMotility");
        JsonNode temps = props.path("temperatureGroup");
        if (temps.isArray() && !temps.isEmpty()) {
            List<BigDecimal> temperatures = new ArrayList<>();
            temps.forEach(t -> temperatures.add(t.decimalValue()));
            readings.put("temperatures", temperatures);
        }
        return readings;
    }

    private static Map<String, Object> decodeHexFallback(String hex, DeviceType deviceType) {
        if (deviceType != DeviceType.CAPSULE || hex == null || hex.isBlank()) {
            return null;
        }
        byte[] bytes = hexToBytes(hex);
        return RumenPayloadDecoder.decode(bytes)
                .map(frame -> frame.toReadings())
                .orElse(null);
    }

    private static byte[] hexToBytes(String hex) {
        String clean = hex.replace(" ", "").replace("\n", "");
        if (clean.length() % 2 != 0) return new byte[0];
        byte[] bytes = new byte[clean.length() / 2];
        for (int i = 0; i < bytes.length; i++) {
            bytes[i] = (byte) Integer.parseInt(clean.substring(i * 2, i * 2 + 2), 16);
        }
        return bytes;
    }

    private interface PointConsumer {
        void accept(long ts, JsonNode value);
    }

    private static void collectPoints(JsonNode timeseries, String key, PointConsumer consumer) {
        JsonNode points = timeseries.path(key);
        if (!points.isArray()) return;
        for (JsonNode point : points) {
            consumer.accept(point.path("ts").asLong(), point.path("value"));
        }
    }

    private static void copyInt(Map<String, Object> readings, JsonNode props,
                                String sourceKey, String targetKey) {
        JsonNode node = props.path(sourceKey);
        if (node.isInt()) readings.put(targetKey, node.asInt());
        else if (node.isLong()) readings.put(targetKey, (int) node.asLong());
        else if (node.isTextual() && node.asText().chars().allMatch(Character::isDigit)) {
            readings.put(targetKey, Integer.parseInt(node.asText()));
        }
    }

    private static void copyDecimal(Map<String, Object> readings, JsonNode props, String key) {
        JsonNode node = props.path(key);
        if (node.isNumber()) readings.put(key, node.decimalValue());
    }

    private static void copyText(Map<String, Object> readings, JsonNode props,
                                 String sourceKey, String targetKey) {
        JsonNode node = props.path(sourceKey);
        if (!node.isMissingNode() && !node.isNull()) readings.put(targetKey, node.asText());
    }
}
