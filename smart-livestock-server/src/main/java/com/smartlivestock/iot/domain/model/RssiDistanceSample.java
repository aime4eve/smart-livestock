package com.smartlivestock.iot.domain.model;

import java.time.Instant;

/**
 * One calibration sample for the dynamic RSSI→distance map: a GPS-valid frame
 * whose receiving gateway position is registered.
 */
public record RssiDistanceSample(int rssi, double distMeters, Instant reportTime) {
}
