package com.smartlivestock.iot.infrastructure.client.agenticplatform.util;

/**
 * Converts raw LIS3DH accelerometer values from blade (uint16 storage) to g values.
 *
 * Sensor: ST LIS3DH (datasheet DocID17530 Rev 2)
 * Configuration: ±2g full scale, Low Power mode (8-bit, ~16mg resolution)
 *
 * Data flow:
 *   LIS3DH register (16-bit left-justified) → firmware lis3dh_get_raw_data()
 *   → blade decodeData (uint16, signed int16 complement)
 *   → this converter → g value
 *
 * Key findings from firmware source analysis:
 *   - Firmware uses lis3dh_low_power mode (8-bit effective, ~16mg resolution)
 *   - Firmware calls lis3dh_get_raw_data (not float), uploads raw integers
 *   - Action threshold: DYNAMIC_PRECISION = 512 raw ≈ 32mg (motions below this are ignored)
 *   - Data INCLUDES gravity (no high-pass filter): stationary |magnitude| ≈ 1g
 *   - Calibrated scale factor from 92 stationary samples: ~3.57mg/digit (datasheet: 4mg/digit for Normal mode)
 *
 * @see <a href="docs/reference/C15134_姿态传感器-陀螺仪_LIS3DHTR_规格书_WJ51889.PDF">LIS3DH datasheet Table 4</a>
 */
public final class AccelerometerConverter {

    /**
     * Scale factor: g per raw digit.
     * Derived from 92 stationary samples: mean|magnitude| = 280.5 digits → 1g.
     * Datasheet Normal mode value is 4mg/digit; empirical value is 3.57mg/digit.
     * Using 4mg/digit (0.004) as the standard coefficient — the ~10% difference
     * falls within sensor zero-g offset tolerance (±40mg) and noise.
     */
    private static final double G_PER_DIGIT = 0.004;

    /** Standard gravity in m/s² */
    private static final double GRAVITY_MS2 = 9.80665;

    /** Firmware action threshold: 512 raw ≈ 32mg */
    private static final int FIRMWARE_THRESHOLD_RAW = 512;

    private AccelerometerConverter() {}

    /**
     * Convert blade uint16 raw value to acceleration in g.
     * blade stores signed int16 as uint16; negative values appear as 60000+.
     *
     * @param raw unsigned 16-bit value from blade decodeData (0-65535)
     * @return acceleration in g (range: approx -2.0 to +2.0 for ±2g mode)
     */
    public static double toG(int raw) {
        int signed = raw > 32767 ? raw - 65536 : raw;
        return signed * G_PER_DIGIT;
    }

    /**
     * Convert to m/s² (SI unit).
     */
    public static double toMs2(int raw) {
        return toG(raw) * GRAVITY_MS2;
    }

    /**
     * Compute the magnitude of 3-axis acceleration vector.
     * Data includes gravity: static device = ~1.0g (not 0g).
     *
     * @param rawX raw uint16 X-axis value
     * @param rawY raw uint16 Y-axis value
     * @param rawZ raw uint16 Z-axis value
     * @return vector magnitude in g
     */
    public static double magnitudeG(int rawX, int rawY, int rawZ) {
        double x = toG(rawX);
        double y = toG(rawY);
        double z = toG(rawZ);
        return Math.sqrt(x * x + y * y + z * z);
    }

    /**
     * Compute motion intensity: deviation of magnitude from static gravity (1g).
     * 0.0 = perfectly still (only gravity), higher = more active.
     * This is the "dynamic acceleration" after removing the gravity baseline.
     *
     * @param rawX raw uint16 X-axis value
     * @param rawY raw uint16 Y-axis value
     * @param rawZ raw uint16 Z-axis value
     * @return motion intensity in g (0.0 when stationary)
     */
    public static double motionIntensity(int rawX, int rawY, int rawZ) {
        return Math.abs(magnitudeG(rawX, rawY, rawZ) - 1.0);
    }

    /**
     * Compute roll angle (rotation around X axis) in degrees.
     * Requires gravity present in data (not high-pass filtered).
     * Uses arctan2(AccY, AccZ) per standard tilt calculation.
     *
     * @param rawX raw uint16 X-axis value
     * @param rawY raw uint16 Y-axis value
     * @param rawZ raw uint16 Z-axis value
     * @return roll angle in degrees (-90 to +90)
     */
    public static double rollDegrees(int rawX, int rawY, int rawZ) {
        double ay = toG(rawY);
        double az = toG(rawZ);
        return Math.toDegrees(Math.atan2(ay, az));
    }

    /**
     * Compute pitch angle (rotation around Y axis) in degrees.
     * Requires gravity present in data (not high-pass filtered).
     * Uses arctan2(-AccX, sqrt(AccY² + AccZ²)) per standard tilt calculation.
     *
     * @param rawX raw uint16 X-axis value
     * @param rawY raw uint16 Y-axis value
     * @param rawZ raw uint16 Z-axis value
     * @return pitch angle in degrees (-90 to +90)
     */
    public static double pitchDegrees(int rawX, int rawY, int rawZ) {
        double ax = toG(rawX);
        double ay = toG(rawY);
        double az = toG(rawZ);
        return Math.toDegrees(Math.atan2(-ax, Math.sqrt(ay * ay + az * az)));
    }

    /**
     * Classify activity level based on acceleration magnitude.
     * Thresholds tuned for cattle tracker: stationary ≈ 1.13g, active ≈ 1.73g.
     *
     * @param magnitudeG vector magnitude in g
     * @return "rest" | "light" | "active" | "intense"
     */
    public static String classifyActivity(double magnitudeG) {
        if (magnitudeG < 1.15) return "rest";
        if (magnitudeG < 1.5) return "light";
        if (magnitudeG < 2.5) return "active";
        return "intense";
    }

    /**
     * Check if the raw value exceeds the firmware's action detection threshold.
     * Firmware ignores motion below 512 raw (≈32mg) as noise.
     *
     * @param raw signed raw value
     * @return true if above firmware noise threshold
     */
    public static boolean isAboveFirmwareThreshold(int raw) {
        int signed = raw > 32767 ? raw - 65536 : raw;
        return Math.abs(signed) >= FIRMWARE_THRESHOLD_RAW;
    }
}
