package com.smartlivestock.iot.domain.model;

/**
 * Recent link quality of one device through one gateway (NIX-219 F3):
 * averages over the most recent frames (rssi required, snr optional).
 */
public record LinkQualityStats(double avgRssi, Double avgSnr, int frames) {

    public enum Tier { STABLE, WEAK, EDGE }

    public Tier tier(double weakThreshold, double edgeThreshold) {
        if (avgRssi < edgeThreshold) return Tier.EDGE;
        if (avgRssi < weakThreshold) return Tier.WEAK;
        return Tier.STABLE;
    }
}
