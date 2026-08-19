package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.DatagenOperatorContext.DatagenOperatorRole;
import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DatagenAuditService {
    private final AuditLogRepository auditLogRepository;

    @Transactional(propagation = Propagation.MANDATORY)
    public void record(
            String action, Long farmId, DatagenOperatorContext operator,
            Map<String, Object> details) {
        Map<String, Object> auditDetails = new LinkedHashMap<>(details);
        auditDetails.put("summaryKey", summaryKey(action));
        AuditLog auditLog = new AuditLog(
                UUID.randomUUID().toString(),
                switch (action) {
                    case "START", "STOP", "UPDATE_DEVICES", "UPDATE_RULES" -> "DATAGEN_CONTROL_CHANGED";
                    case "CLEAR_DATA" -> "DATAGEN_DATA_CLEARED";
                    default -> throw new IllegalArgumentException("Unknown datagen audit action: " + action);
                },
                operator.tenantId(),
                operator.userId(),
                action,
                auditDetails,
                Instant.now(),
                farmId,
                operator.role() == DatagenOperatorRole.PLATFORM_ADMIN
                        ? "PLATFORM_ADMIN" : "B2B_ADMIN");
        auditLogRepository.save(auditLog);
    }

    private String summaryKey(String action) {
        return switch (action) {
            case "START" -> "datagenConsoleOperationStart";
            case "STOP" -> "datagenConsoleOperationStop";
            case "UPDATE_DEVICES" -> "datagenConsoleOperationUpdateDevices";
            case "UPDATE_RULES" -> "datagenConsoleOperationUpdateRules";
            case "CLEAR_DATA" -> "datagenConsoleOperationClear";
            default -> action;
        };
    }
}
