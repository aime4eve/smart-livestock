package com.smartlivestock.health.domain.port.dto;

public record AlertInfo(Long farmId, Long livestockId, String alertType,
                        String severity, String message, String source) {
    // Backward-compat: callers that don't specify source default to RULE
    public AlertInfo(Long farmId, Long livestockId, String alertType,
                     String severity, String message) {
        this(farmId, livestockId, alertType, severity, message, "RULE");
    }
}
