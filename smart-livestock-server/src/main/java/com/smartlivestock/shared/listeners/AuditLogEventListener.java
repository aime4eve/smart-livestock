package com.smartlivestock.shared.listeners;

import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.shared.domain.DomainEvent;
import com.smartlivestock.shared.domain.event.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class AuditLogEventListener {

    private final AuditLogRepository auditLogRepository;

    @EventListener
    public void handleDomainEvent(DomainEvent event) {
        try {
            Long userId = getCurrentUserId();
            Long tenantId = extractTenantId(event);
            String action = deriveAction(event);
            Map<String, Object> details = extractDetails(event);

            AuditLog auditLog = new AuditLog(
                    event.getEventId(),
                    event.getClass().getSimpleName(),
                    tenantId,
                    userId,
                    action,
                    details,
                    event.getOccurredAt()
            );
            auditLogRepository.save(auditLog);
            log.debug("Audit log saved: {} [{}]", action, event.getClass().getSimpleName());
        } catch (Exception e) {
            log.warn("Failed to save audit log for event {}: {}", event.getClass().getSimpleName(), e.getMessage());
        }
    }

    private Long getCurrentUserId() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getPrincipal() instanceof Long userId) {
                return userId;
            }
        } catch (Exception ignored) {}
        return null;
    }

    private Long extractTenantId(DomainEvent event) {
        try {
            Method m = event.getClass().getMethod("getTenantId");
            return (Long) m.invoke(event);
        } catch (Exception e) {
            return null;
        }
    }

    private String deriveAction(DomainEvent event) {
        String name = event.getClass().getSimpleName();
        // SubscriptionTierChangedEvent → SUBSCRIPTION_TIER_CHANGED
        return name.replace("Event", "").replaceAll("([a-z])([A-Z])", "$1_$2").toUpperCase();
    }

    private Map<String, Object> extractDetails(DomainEvent event) {
        Map<String, Object> details = new HashMap<>();
        if (event instanceof SubscriptionTierChangedEvent e) {
            details.put("oldTier", e.getOldTier());
            details.put("newTier", e.getNewTier());
        } else if (event instanceof SubscriptionReactivatedEvent e) {
            details.put("tenantId", e.getTenantId());
        } else if (event instanceof ContractSignedEvent e) {
            details.put("contractNumber", e.getContractNumber());
        } else if (event instanceof ServiceRevokedEvent e) {
            details.put("serviceName", e.getServiceName());
        }
        return details.isEmpty() ? null : details;
    }
}
