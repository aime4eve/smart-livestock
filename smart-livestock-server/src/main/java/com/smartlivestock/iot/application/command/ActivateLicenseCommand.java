package com.smartlivestock.iot.application.command;

public record ActivateLicenseCommand(Long deviceId, Long tenantId) {
}
