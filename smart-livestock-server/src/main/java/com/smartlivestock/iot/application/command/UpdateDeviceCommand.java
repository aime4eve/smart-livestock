package com.smartlivestock.iot.application.command;

public record UpdateDeviceCommand(String deviceCode, String devEui) {
}
