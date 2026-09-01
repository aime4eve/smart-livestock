package com.smartlivestock.iot.domain.service;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * Decoder for rumen capsule standard TLV uplink payloads.
 * <p>
 * Frame layout is defined in
 * {@code docs/protocols/LoRa WAN瘤胃胶囊上行Payload解析协议定义.md}.
 */
public final class RumenPayloadDecoder {

    private static final int HEADER_LENGTH = 5;

    private static final int TYPE_VERSION = 0x01;
    private static final int TYPE_BATTERY_PERCENT = 0x03;
    private static final int TYPE_TEMPERATURE = 0x09;
    private static final int TYPE_LEGACY_GASTRIC_MOTILITY_V1 = 0x00;
    private static final int TYPE_LEGACY_GASTRIC_MOTILITY = 0x24;
    private static final int TYPE_TEMPERATURE_GROUP = 0x4D;
    private static final int TYPE_LEGACY_TEMPERATURE_GROUP = 0x45;
    private static final int TYPE_BATTERY_VOLTAGE = 0x8B;
    private static final int TYPE_GASTRIC_MOTILITY = 0x49;
    private static final int TYPE_ACCEL_X = 0x4A;
    private static final int TYPE_ACCEL_Y = 0x4B;
    private static final int TYPE_ACCEL_Z = 0x4C;
    private static final int TYPE_TIMESTAMP = 0x4E;
    private static final int TYPE_REPORT_INTERVAL = 0x86;
    private static final int TYPE_ACK = 0xFF;

    // Production devices also emit earlier firmware revisions: 0x45 temperature
    // groups and 0x00/0x24 gastric motility values.
    private RumenPayloadDecoder() {}

    public static Optional<DecodedRumenFrame> decode(byte[] bytes) {
        if (bytes == null || bytes.length < HEADER_LENGTH
                || (bytes[0] & 0xFF) != 0x68
                || (bytes[1] & 0xFF) != 0x6B
                || (bytes[2] & 0xFF) != 0x74) {
            return Optional.empty();
        }

        DecodedRumenFrame frame = new DecodedRumenFrame(bytes[3] & 0xFF, bytes[4] & 0xFF);
        int offset = HEADER_LENGTH;
        boolean legacyTemperatureFrame = false;
        while (offset < bytes.length) {
            int type = bytes[offset] & 0xFF;
            int valueLength = valueLengthOf(type, bytes, offset, legacyTemperatureFrame);
            if (valueLength < 0 || offset + 1 + valueLength > bytes.length) {
                return Optional.empty();
            }

            int value = offset + 1;
            switch (type) {
                case TYPE_VERSION -> {
                    // Consumed for framing only; readings do not expose firmware versions.
                }
                case TYPE_BATTERY_PERCENT -> frame.setBatteryPercent(bytes[value] & 0xFF);
                case TYPE_TEMPERATURE_GROUP, TYPE_LEGACY_TEMPERATURE_GROUP ->
                        decodeTemperatureGroup(frame, bytes, value);
                case TYPE_BATTERY_VOLTAGE -> {
                    if (!legacyTemperatureFrame) {
                        frame.setBatteryVoltage(readU16(bytes, value));
                    }
                }
                case TYPE_GASTRIC_MOTILITY, TYPE_LEGACY_GASTRIC_MOTILITY,
                        TYPE_LEGACY_GASTRIC_MOTILITY_V1 ->
                        frame.setGastricMotility(type == TYPE_LEGACY_GASTRIC_MOTILITY_V1
                                ? readU24(bytes, value)
                                : readU32(bytes, value));
                case TYPE_ACCEL_X -> frame.setAccelXRaw(bytes[value] & 0xFF);
                case TYPE_ACCEL_Y -> frame.setAccelYRaw(bytes[value] & 0xFF);
                case TYPE_ACCEL_Z -> frame.setAccelZRaw(bytes[value] & 0xFF);
                case TYPE_REPORT_INTERVAL -> frame.setReportIntervalMinutes(readU16(bytes, value));
                default -> {
                    // TYPE_TEMPERATURE and TYPE_ACK are consumed for framing only.
                }
            }
            offset += 1 + valueLength;
            if (type == TYPE_LEGACY_TEMPERATURE_GROUP) {
                legacyTemperatureFrame = true;
            }
        }
        return Optional.of(frame);
    }

    private static int valueLengthOf(
            int type, byte[] bytes, int offset, boolean legacyTemperatureFrame) {
        return switch (type) {
            case TYPE_VERSION, TYPE_BATTERY_VOLTAGE, TYPE_REPORT_INTERVAL -> 2;
            case TYPE_BATTERY_PERCENT, TYPE_ACCEL_X, TYPE_ACCEL_Y, TYPE_ACCEL_Z, TYPE_ACK -> 1;
            case TYPE_TEMPERATURE -> 3;
            case TYPE_LEGACY_GASTRIC_MOTILITY_V1 -> legacyTemperatureFrame ? 3 : -1;
            case TYPE_GASTRIC_MOTILITY, TYPE_LEGACY_GASTRIC_MOTILITY, TYPE_TIMESTAMP -> 4;
            case TYPE_TEMPERATURE_GROUP, TYPE_LEGACY_TEMPERATURE_GROUP -> {
                if (offset + 1 >= bytes.length) yield -1;
                yield 1 + (bytes[offset + 1] & 0xFF) * 2;
            }
            default -> -1;
        };
    }

    private static void decodeTemperatureGroup(DecodedRumenFrame frame, byte[] bytes, int offset) {
        int count = bytes[offset] & 0xFF;
        for (int i = 0; i < count; i++) {
            int raw = readU16(bytes, offset + 1 + i * 2);
            BigDecimal temperature = (raw & 0x8000) != 0
                    ? BigDecimal.valueOf(raw & 0x7FFF, 2).negate()
                    : BigDecimal.valueOf(raw, 2);
            frame.temperatures().add(temperature);
        }
    }

    private static int readU16(byte[] bytes, int offset) {
        return ((bytes[offset] & 0xFF) << 8) | (bytes[offset + 1] & 0xFF);
    }

    private static long readU32(byte[] bytes, int offset) {
        return ((bytes[offset] & 0xFFL) << 24)
                | ((bytes[offset + 1] & 0xFFL) << 16)
                | ((bytes[offset + 2] & 0xFFL) << 8)
                | (bytes[offset + 3] & 0xFFL);
    }

    private static long readU24(byte[] bytes, int offset) {
        return ((bytes[offset] & 0xFFL) << 16)
                | ((bytes[offset + 1] & 0xFFL) << 8)
                | (bytes[offset + 2] & 0xFFL);
    }
}
