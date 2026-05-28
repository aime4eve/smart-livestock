package com.smartlivestock.iot.application.command;

public record InstallDeviceCommand(Long deviceId, Long livestockId, Long operatorId) {
}
