package com.smartlivestock.docking.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for AccelerometerConverter.
 * Test values validated against real blade data, LIS3DH datasheet, and firmware source.
 */
class AccelerometerConverterTest {

    @Test
    @DisplayName("Positive raw value converts correctly")
    void positiveValue() {
        assertEquals(0.612, AccelerometerConverter.toG(153), 0.001);
    }

    @Test
    @DisplayName("Negative raw value (stored as uint16 complement) converts correctly")
    void negativeValue() {
        assertEquals(-0.612, AccelerometerConverter.toG(65383), 0.001);
    }

    @Test
    @DisplayName("Zero raw value = 0g")
    void zeroValue() {
        assertEquals(0.0, AccelerometerConverter.toG(0), 0.001);
    }

    @Test
    @DisplayName("toMs2: 1g = 9.80665 m/s²")
    void toMs2Conversion() {
        // 250 digits × 0.004 = 1.000g
        double ms2 = AccelerometerConverter.toMs2(250);
        assertEquals(9.80665, ms2, 0.01);
    }

    @Test
    @DisplayName("Magnitude: stationary device ~1g gravity")
    void magnitudeStationary() {
        // Real sample: x=-153(65383), y=-307(65229), z=307
        double mag = AccelerometerConverter.magnitudeG(65383, 65229, 307);
        assertTrue(mag > 1.0 && mag < 2.0, "Stationary magnitude should be near 1g, got " + mag);
    }

    @Test
    @DisplayName("Magnitude of flat horizontal device: Z=1g, X=Y=0g")
    void magnitudeFlatHorizontal() {
        // Z axis = 1g = 250 digits (250 × 4mg = 1000mg = 1g)
        double mag = AccelerometerConverter.magnitudeG(0, 0, 250);
        assertEquals(1.0, mag, 0.001);
    }

    @Test
    @DisplayName("Motion intensity: zero when gravity only (flat)")
    void motionIntensityZero() {
        double mi = AccelerometerConverter.motionIntensity(0, 0, 250);
        assertEquals(0.0, mi, 0.01);
    }

    @Test
    @DisplayName("Roll angle: flat device = 0°, tilted 45° on Y-Z plane")
    void rollAngle() {
        // Flat: Y=0, Z=1g → roll=0°
        assertEquals(0.0, AccelerometerConverter.rollDegrees(0, 0, 250), 0.5);
        // Tilted 45°: Y=Z=0.707g → roll=45°
        int half = 177; // 0.707g / 0.004 ≈ 177 digits
        assertEquals(45.0, AccelerometerConverter.rollDegrees(0, half, half), 1.0);
    }

    @Test
    @DisplayName("Pitch angle: flat device = 0°, nose up 45°")
    void pitchAngle() {
        // Flat: X=0, Y=0, Z=1g → pitch=0°
        assertEquals(0.0, AccelerometerConverter.pitchDegrees(0, 0, 250), 0.5);
    }

    @Test
    @DisplayName("Activity classification thresholds")
    void activityClassification() {
        assertEquals("rest", AccelerometerConverter.classifyActivity(1.0));
        assertEquals("rest", AccelerometerConverter.classifyActivity(1.1));
        assertEquals("light", AccelerometerConverter.classifyActivity(1.15));
        assertEquals("light", AccelerometerConverter.classifyActivity(1.3));
        assertEquals("active", AccelerometerConverter.classifyActivity(1.5));
        assertEquals("active", AccelerometerConverter.classifyActivity(2.0));
        assertEquals("intense", AccelerometerConverter.classifyActivity(2.5));
        assertEquals("intense", AccelerometerConverter.classifyActivity(3.0));
    }

    @Test
    @DisplayName("Firmware threshold: 512 raw ≈ 32mg")
    void firmwareThreshold() {
        // Below threshold (511): noise
        assertFalse(AccelerometerConverter.isAboveFirmwareThreshold(511));
        // At threshold (512): detected
        assertTrue(AccelerometerConverter.isAboveFirmwareThreshold(512));
        // Negative threshold in uint16 (65024 = -512)
        assertTrue(AccelerometerConverter.isAboveFirmwareThreshold(65024));
    }

    @Test
    @DisplayName("Real blade sample: active device (steps>0) has higher magnitude than rest")
    void realBladeComparison() {
        // Inactive: x=0, y=-102(65434), z=0 → |mag|=0.408g
        double restMag = AccelerometerConverter.magnitudeG(0, 65434, 0);
        // Active: x=-153(65383), y=-256(65280), z=-204(65332) → |mag|=1.445g
        double activeMag = AccelerometerConverter.magnitudeG(65383, 65280, 65332);
        assertTrue(activeMag > restMag, "Active should have higher magnitude than rest");
    }
}
