package com.smartlivestock.iot.domain.model;

public enum DeviceType {
    EAR_TAG,
    TRACKER,
    CAPSULE;

    public boolean supportsGps() {
        return this == TRACKER || this == EAR_TAG;
    }
}
