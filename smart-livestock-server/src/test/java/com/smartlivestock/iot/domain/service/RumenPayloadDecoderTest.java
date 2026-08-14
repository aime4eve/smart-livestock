package com.smartlivestock.iot.domain.service;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

class RumenPayloadDecoderTest {

    private static final String NS_UPLINK =
            "68 6B 74 00 32 01 10 07 4D 00 8B 0B DA 49 00 00 3F 10 4A DE 4B 02 4C 40 86 00 F0";

    @Test
    void decode_nsUplink_extractsCapsuleReadings() {
        Optional<DecodedRumenFrame> result = RumenPayloadDecoder.decode(hex(NS_UPLINK));

        assertTrue(result.isPresent());
        Map<String, Object> readings = result.get().toReadings();
        assertEquals(50, result.get().getPackSyncNumber());
        assertEquals(3034, readings.get("batteryVoltage"));
        assertEquals(89, readings.get("battery"));
        assertEquals(16144L, readings.get("gastricMotility"));
        assertEquals(222, readings.get("accelXRaw"));
        assertEquals(2, readings.get("accelYRaw"));
        assertEquals(64, readings.get("accelZRaw"));
        assertEquals(240, readings.get("reportIntervalMinutes"));
        assertTrue(((java.util.List<?>) readings.get("temperatures")).isEmpty());
    }

    @Test
    void decode_temperatureGroup_convertsPositiveAndNegativeValues() {
        Optional<DecodedRumenFrame> result = RumenPayloadDecoder.decode(
                hex("68 6B 74 00 01 4D 02 0F 20 80 10"));

        assertTrue(result.isPresent());
        assertEquals(
                java.util.List.of(new BigDecimal("38.72"), new BigDecimal("-0.16")),
                result.get().toReadings().get("temperatures"));
    }

    @Test
    void decode_truncatedOrUnknownTlv_returnsEmpty() {
        assertTrue(RumenPayloadDecoder.decode(hex("68 6B 74 00 32 4D 02 0F")).isEmpty());
        assertTrue(RumenPayloadDecoder.decode(hex("68 6B 74 00 32 20 01")).isEmpty());
        assertTrue(RumenPayloadDecoder.decode(hex("C1 00 0D 4F")).isEmpty());
    }

    private static byte[] hex(String value) {
        String clean = value.replace(" ", "").replace("\n", "");
        byte[] bytes = new byte[clean.length() / 2];
        for (int i = 0; i < bytes.length; i++) {
            bytes[i] = (byte) Integer.parseInt(clean.substring(i * 2, i * 2 + 2), 16);
        }
        return bytes;
    }
}
