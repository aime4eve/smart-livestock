package com.smartlivestock.iot.domain.service;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * Decoder for LoRaWAN cattle/sheep tracker uplink payloads (NIX-79).
 * <p>
 * Java port of the firmware packing protocol — the single authoritative source
 * is {@code docs/protocols/LoRaWAN 牛羊追踪器上行 Payload 解析协议定义.md}
 * (the platform JS decoder is known to diverge from the firmware and is NOT
 * used as a reference).
 * <p>
 * Frame layout: 3-byte sync head {@code 68 6B 74} + special_type +
 * pack_sync_number, then a sequence of {@code type + value} TLV blocks whose
 * lengths are implied by the type byte. Multi-byte values are big-endian.
 * <p>
 * Returns {@link Optional#empty()} for: non-sync-head frames (other device
 * models / registration frames), unknown TLV types (the stream cannot be
 * advanced past them), and truncated frames.
 */
public final class TrackerPayloadDecoder {

    private static final int SYNC_0 = 0x68;
    private static final int SYNC_1 = 0x6B;
    private static final int SYNC_2 = 0x74;
    private static final int HEADER_LENGTH = 5;

    // TLV types (protocol §4)
    private static final int TYPE_VERSION = 0x01;            // 2 bytes, not mapped
    private static final int TYPE_DEVICE_ID = 0x02;          // 6 bytes, not mapped
    private static final int TYPE_BATTERY = 0x03;            // 1 byte  → battery
    private static final int TYPE_TEMPERATURE = 0x09;        // 3 bytes, skipped (scale unconfirmed, §6.4)
    private static final int TYPE_HUMIDITY = 0x0A;           // 3 bytes, skipped (scale unconfirmed, §6.5)
    private static final int TYPE_ACCEL_X = 0x0B;            // 2 bytes s16 → accelXRaw
    private static final int TYPE_ACCEL_Y = 0x0C;            // 2 bytes s16 → accelYRaw
    private static final int TYPE_ACCEL_Z = 0x0D;            // 2 bytes s16 → accelZRaw
    private static final int TYPE_LATITUDE = 0x10;           // 4 bytes special u32 → latitude
    private static final int TYPE_LONGITUDE = 0x11;          // 4 bytes special u32 → longitude
    private static final int TYPE_STEP_COUNT = 0x15;         // 2 bytes u16 → stepCount (per-cycle, §6.9)
    private static final int TYPE_ACTIVE_SYNC = 0x32;        // 1 byte, skipped
    private static final int TYPE_RUN_MODE_CONFIG = 0x39;    // 15 bytes, skipped
    private static final int TYPE_POWER_SUPPLY = 0x81;       // 1 byte, skipped
    private static final int TYPE_WORK_MODE = 0x82;          // 1 byte, skipped
    private static final int TYPE_FAULT_STATUS = 0x83;       // 1 byte, skipped
    private static final int TYPE_ANTI_DISASSEMBLY = 0x84;   // 1 byte  → antiDisassemblyStatus
    private static final int TYPE_ACK = 0xFF;                // 1 byte, skipped

    private TrackerPayloadDecoder() {}

    /**
     * Decode one uplink frame.
     *
     * @param bytes raw payload
     * @return decoded frame, or empty when the frame is not a decodable
     *         cattle/sheep tracker uplink (bad sync head, unknown TLV type,
     *         truncation)
     */
    public static Optional<DecodedTrackerFrame> decode(byte[] bytes) {
        if (bytes == null || bytes.length < HEADER_LENGTH) {
            return Optional.empty();
        }
        if ((bytes[0] & 0xFF) != SYNC_0 || (bytes[1] & 0xFF) != SYNC_1 || (bytes[2] & 0xFF) != SYNC_2) {
            return Optional.empty();
        }

        DecodedTrackerFrame frame = new DecodedTrackerFrame(bytes[3] & 0xFF, bytes[4] & 0xFF);

        int offset = HEADER_LENGTH;
        while (offset < bytes.length) {
            int type = bytes[offset] & 0xFF;
            int valueLength = valueLengthOf(type);
            if (valueLength < 0) {
                // Unknown type: value length unknowable, stream cannot continue
                return Optional.empty();
            }
            if (offset + 1 + valueLength > bytes.length) {
                // Truncated value
                return Optional.empty();
            }
            int v = offset + 1;
            switch (type) {
                case TYPE_BATTERY -> frame.setBattery(bytes[v] & 0xFF);
                case TYPE_ACCEL_X -> frame.setAccelXRaw(readS16(bytes, v));
                case TYPE_ACCEL_Y -> frame.setAccelYRaw(readS16(bytes, v));
                case TYPE_ACCEL_Z -> frame.setAccelZRaw(readS16(bytes, v));
                case TYPE_LATITUDE -> frame.setLatitude(readCoordinate(bytes, v));
                case TYPE_LONGITUDE -> frame.setLongitude(readCoordinate(bytes, v));
                case TYPE_STEP_COUNT -> frame.setStepCount(readU16(bytes, v));
                case TYPE_ANTI_DISASSEMBLY -> frame.setAntiDisassemblyStatus(bytes[v] & 0xFF);
                default -> {
                    // Consumed for framing only: version, device id,
                    // temperature/humidity, active sync, run-mode config,
                    // power/work/fault mode, ACK
                }
            }
            offset += 1 + valueLength;
        }
        return Optional.of(frame);
    }

    /** Value length implied by the TLV type, or -1 for unknown types. */
    private static int valueLengthOf(int type) {
        return switch (type) {
            case TYPE_VERSION -> 2;
            case TYPE_DEVICE_ID -> 6;
            case TYPE_BATTERY -> 1;
            case TYPE_TEMPERATURE, TYPE_HUMIDITY -> 3;
            case TYPE_ACCEL_X, TYPE_ACCEL_Y, TYPE_ACCEL_Z -> 2;
            case TYPE_LATITUDE, TYPE_LONGITUDE -> 4;
            case TYPE_STEP_COUNT -> 2;
            case TYPE_ACTIVE_SYNC -> 1;
            case TYPE_RUN_MODE_CONFIG -> 15;
            case TYPE_POWER_SUPPLY, TYPE_WORK_MODE, TYPE_FAULT_STATUS,
                 TYPE_ANTI_DISASSEMBLY, TYPE_ACK -> 1;
            default -> -1;
        };
    }

    /** Big-endian two's-complement s16. */
    private static int readS16(byte[] bytes, int offset) {
        return (short) (((bytes[offset] & 0xFF) << 8) | (bytes[offset + 1] & 0xFF));
    }

    /** Big-endian unsigned u16. */
    private static int readU16(byte[] bytes, int offset) {
        return ((bytes[offset] & 0xFF) << 8) | (bytes[offset + 1] & 0xFF);
    }

    /**
     * Special u32 coordinate (protocol §3/§6.7): decimal degrees × 1e6;
     * negative values have bit31 set on the absolute value.
     */
    private static BigDecimal readCoordinate(byte[] bytes, int offset) {
        long raw = ((bytes[offset] & 0xFFL) << 24)
                | ((bytes[offset + 1] & 0xFFL) << 16)
                | ((bytes[offset + 2] & 0xFFL) << 8)
                | (bytes[offset + 3] & 0xFFL);
        long value = raw > 0x7FFFFFFFL ? -(raw & 0x7FFFFFFFL) : raw;
        return BigDecimal.valueOf(value, 6);
    }
}
