package com.smartlivestock.iot.domain.model;

/**
 * One RSSI-bucket row of a gateway's dynamic RSSI→distance map (NIX-219 plan B,
 * method from WiMOB 2019). bucketRssi is the bucket centre in dBm (5 dB grid).
 */
public record GatewayDistanceProfileRow(
        int bucketRssi,
        int sampleCount,
        double p50Meters,
        double p90Meters) {
}
