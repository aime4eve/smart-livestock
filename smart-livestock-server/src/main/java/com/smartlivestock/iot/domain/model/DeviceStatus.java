package com.smartlivestock.iot.domain.model;

public enum DeviceStatus {
    INVENTORY,
    ACTIVE,
    // OFFLINE removed — runtime online/offline is expressed by runtimeStatus
    DECOMMISSIONED
}
