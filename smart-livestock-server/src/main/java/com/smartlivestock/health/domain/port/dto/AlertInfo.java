package com.smartlivestock.health.domain.port.dto;

import java.util.List;

public record AlertInfo(Long farmId, Long livestockId, String alertType,
                        String severity, String message, String source,
                        String messageKey, List<?> messageArgs) {
    // Backward-compat: callers that don't specify source default to RULE
    public AlertInfo(Long farmId, Long livestockId, String alertType,
                     String severity, String message) {
        this(farmId, livestockId, alertType, severity, message, "RULE", null, null);
    }
}
