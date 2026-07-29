package com.smartlivestock.iot.domain.service;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * TrackerPayloadDecoder tests using real frames from device 0095690600028577
 * (business-platform/mqtt-decode/0095690600028577-历史数据.xlsx) plus the
 * negative fixtures pinned in the NIX-79 plan.
 */
class TrackerPayloadDecoderTest {

    /** Real periodic report frame: fcnt=119, report time 2026-07-23 16:09:11. */
    private static final String REAL_PERIODIC_FRAME =
            "68 6B 74 00 BC 01 04 04 03 63 10 01 AF 02 F9 11 06 B9 F8 C2 15 00 1B "
                    + "0B FC 67 0C FD 67 0D FB 00 39 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01";

    /** ACK-ish frame carrying unknown TLV type 0x30. */
    private static final String UNKNOWN_TYPE_30_FRAME =
            "68 6B 74 02 02 30 02 FF 63 B0 5D 64 50";

    /** Registration/other-model frame without the 68 6B 74 sync head. */
    private static final String NON_SYNC_HEAD_FRAME =
            "61 00 01 00 04 06 00 00 00 00 00 00 00 00 10 00 01 00 00 1A 01 03 FF 00 02 "
                    + "31 52 31 36 53 2D 52 45 56 2E 42 00";

    /** Sync-head frame carrying unknown TLV type 0x8A. */
    private static final String UNKNOWN_TYPE_8A_FRAME =
            "68 6B 74 02 01 FF 0A 01 11 19 03 64 8A 08 57 64 53 05 52 00 00 00 00 "
                    + "00 00 00 00 00 00 00 56 00 84 00 86 05 A0 54 63 B0 5C 9D 41";

    private static byte[] hex(String spacedHex) {
        String cleaned = spacedHex.replaceAll("\\s+", "");
        byte[] out = new byte[cleaned.length() / 2];
        for (int i = 0; i < out.length; i++) {
            out[i] = (byte) Integer.parseInt(cleaned.substring(i * 2, i * 2 + 2), 16);
        }
        return out;
    }

    @Test
    void decode_realPeriodicFrame_extractsAllFields() {
        Optional<DecodedTrackerFrame> result = TrackerPayloadDecoder.decode(hex(REAL_PERIODIC_FRAME));

        assertTrue(result.isPresent());
        DecodedTrackerFrame frame = result.get();
        assertEquals(99, frame.getBattery());
        assertEquals(new BigDecimal("28.246777"), frame.getLatitude());
        assertEquals(new BigDecimal("112.851138"), frame.getLongitude());
        assertEquals(27, frame.getStepCount());
        assertEquals(-921, frame.getAccelXRaw());
        assertEquals(-665, frame.getAccelYRaw());
        assertEquals(-1280, frame.getAccelZRaw());
        assertNull(frame.getAntiDisassemblyStatus());
    }

    @Test
    void toReadings_realPeriodicFrame_matchesPlatformKeyConventions() {
        Map<String, Object> readings = TrackerPayloadDecoder.decode(hex(REAL_PERIODIC_FRAME))
                .orElseThrow()
                .toReadings();

        assertEquals(99, readings.get("battery"));
        assertEquals(new BigDecimal("28.246777"), readings.get("latitude"));
        assertEquals(new BigDecimal("112.851138"), readings.get("longitude"));
        // Per-cycle steps → stepCount; stepNumber must never be written (spec §4.5)
        assertEquals(27, readings.get("stepCount"));
        assertFalse(readings.containsKey("stepNumber"));

        assertEquals(-921, readings.get("accelXRaw"));
        assertEquals(-665, readings.get("accelYRaw"));
        assertEquals(-1280, readings.get("accelZRaw"));
        // g conversion: 0.004 per digit
        assertEquals(-3.684, (double) readings.get("accelXG"), 1e-9);
        assertEquals(-2.66, (double) readings.get("accelYG"), 1e-9);
        assertEquals(-5.12, (double) readings.get("accelZG"), 1e-9);
        // |(-3.684, -2.66, -5.12)| ≈ 6.8456 → intense (>= 2.5)
        assertEquals(6.8456, (double) readings.get("accelMagnitudeG"), 1e-3);
        assertEquals(5.8456, (double) readings.get("motionIntensity"), 1e-3);
        assertEquals("intense", readings.get("activityClass"));
        assertTrue(readings.containsKey("rollDegrees"));
        assertTrue(readings.containsKey("pitchDegrees"));
    }

    @Test
    void decode_unknownType30_returnsEmpty() {
        assertTrue(TrackerPayloadDecoder.decode(hex(UNKNOWN_TYPE_30_FRAME)).isEmpty());
    }

    @Test
    void decode_nonSyncHead_returnsEmpty() {
        assertTrue(TrackerPayloadDecoder.decode(hex(NON_SYNC_HEAD_FRAME)).isEmpty());
    }

    @Test
    void decode_unknownType8A_returnsEmpty() {
        assertTrue(TrackerPayloadDecoder.decode(hex(UNKNOWN_TYPE_8A_FRAME)).isEmpty());
    }

    @Test
    void decode_nullOrEmpty_returnsEmpty() {
        assertTrue(TrackerPayloadDecoder.decode(null).isEmpty());
        assertTrue(TrackerPayloadDecoder.decode(new byte[0]).isEmpty());
    }

    @Test
    void decode_shorterThanHeader_returnsEmpty() {
        assertTrue(TrackerPayloadDecoder.decode(hex("68 6B 74")).isEmpty());
        assertTrue(TrackerPayloadDecoder.decode(hex("68 6B 74 00")).isEmpty());
    }

    @Test
    void decode_truncatedTlvValue_returnsEmpty() {
        // Declares a 4-byte latitude but only 2 bytes follow
        assertTrue(TrackerPayloadDecoder.decode(hex("68 6B 74 00 01 10 01 AF")).isEmpty());
        // Header-only frame (no TLV at all) decodes to an empty-value frame
        Optional<DecodedTrackerFrame> headerOnly = TrackerPayloadDecoder.decode(hex("68 6B 74 00 01"));
        assertTrue(headerOnly.isPresent());
        assertTrue(headerOnly.get().toReadings().isEmpty());
    }

    @Test
    void decode_zeroZeroCoordinate_decodesToZero() {
        // (0,0) means "no fix": the decoder reports it faithfully; the (0,0)
        // skip is an ingestion concern, not a decoding one.
        Optional<DecodedTrackerFrame> result = TrackerPayloadDecoder.decode(
                hex("68 6B 74 00 01 10 00 00 00 00 11 00 00 00 00"));

        assertTrue(result.isPresent());
        assertEquals(0, result.get().getLatitude().compareTo(BigDecimal.ZERO));
        assertEquals(0, result.get().getLongitude().compareTo(BigDecimal.ZERO));
    }

    @Test
    void decode_negativeCoordinate_bit31Set() {
        // -(1) → abs×1e6 | 0x80000000 = 0x80000001
        Optional<DecodedTrackerFrame> result = TrackerPayloadDecoder.decode(
                hex("68 6B 74 00 01 10 80 00 00 01"));

        assertTrue(result.isPresent());
        assertEquals(new BigDecimal("-0.000001"), result.get().getLatitude());
    }

    @Test
    void decode_antiDisassemblyAndSkippedTypes_consumedWithoutMapping() {
        // 0x84 mapped; 0x01 version / 0x02 device id / 0x32 sync / 0xFF ack consumed
        Optional<DecodedTrackerFrame> result = TrackerPayloadDecoder.decode(
                hex("68 6B 74 00 01 01 04 03 02 11 22 33 44 55 66 84 01 32 00 FF FF"));

        assertTrue(result.isPresent());
        DecodedTrackerFrame frame = result.get();
        assertEquals(1, frame.getAntiDisassemblyStatus());
        Map<String, Object> readings = frame.toReadings();
        assertEquals(1, readings.get("antiDisassemblyStatus"));
        assertEquals(1, readings.size());
    }
}
