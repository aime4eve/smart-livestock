package com.smartlivestock.identity.application;

import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataFarmRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataTenantRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataUserRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.TenantJpaEntity;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Tenant lifecycle (ruling 2026-10-14): active ⇄ disabled (reversible) and
 * soft delete (recoverable). Business data is never physically removed —
 * audit trail and history stay intact. Pre-conditions block tenants with
 * business ties (ACTIVE devices / live subscription); tie-free tenants
 * (e.g. dev test tenants) delete directly.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TenantLifecycleService {

    private final SpringDataTenantRepository tenantRepository;
    private final SpringDataUserRepository userRepository;
    private final SpringDataFarmRepository farmRepository;
    private final com.smartlivestock.commerce.infrastructure.persistence.SpringDataSubscriptionRepository subscriptionRepository;
    private final DeviceRepository deviceRepository;
    private final AuditLogRepository auditLogRepository;

    @Transactional
    public void updateStatus(Long tenantId, String status, Long operatorId) {
        TenantJpaEntity tenant = requireLive(tenantId);
        tenant.setStatus(status);
        tenant.setUpdatedAt(Instant.now());
        tenantRepository.save(tenant);
        audit(operatorId, tenant, "TENANT_STATUS_CHANGED",
                Map.of("status", status));
    }

    /**
     * Soft delete with business-continuity pre-conditions: ACTIVE devices and
     * a live (trial/active) subscription block the delete; everything else
     * (e.g. dev test tenants) deletes directly. Cascade: all users disabled,
     * subscriptions cancelled, farms soft-deleted, tenant row marked.
     */
    @Transactional
    public void delete(Long tenantId, Long operatorId) {
        delete(tenantId, operatorId, false);
    }

    /**
     * @param cancelSubscription when true, a live (trial/active) subscription
     *        is cancelled as part of the cascade instead of blocking the
     *        delete — the UI checkbox path for tie-light tenants
     *        (ruling follow-up 2026-10-14).
     */
    @Transactional
    public void delete(Long tenantId, Long operatorId, boolean cancelSubscription) {
        TenantJpaEntity tenant = requireLive(tenantId);

        long activeDevices = deviceRepository.findByTenantId(tenantId).stream()
                .filter(d -> "ACTIVE".equals(d.getStatus() == null ? null : d.getStatus().name()))
                .count();
        if (activeDevices > 0) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "tenant.deleteActiveDevices",
                    new Object[]{activeDevices});
        }
        boolean liveSubscription = subscriptionRepository.findByTenantId(tenantId)
                .map(sub -> "trial".equalsIgnoreCase(sub.getStatus())
                        || "active".equalsIgnoreCase(sub.getStatus()))
                .orElse(false);
        if (liveSubscription && !cancelSubscription) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "tenant.deleteLiveSubscription");
        }

        userRepository.findAll().stream()
                .filter(u -> tenantId.equals(u.getTenantId()))
                .forEach(u -> {
                    u.setIsActive(false);
                    userRepository.save(u);
                });
        subscriptionRepository.findByTenantId(tenantId).ifPresent(sub -> {
            sub.setStatus("cancelled");
            subscriptionRepository.save(sub);
        });
        farmRepository.findByTenantId(tenantId).forEach(farm -> {
            farm.setDeletedAt(Instant.now());
            farmRepository.save(farm);
        });

        tenant.setDeletedAt(Instant.now());
        tenant.setUpdatedAt(Instant.now());
        tenantRepository.save(tenant);
        audit(operatorId, tenant, "TENANT_DELETED", Map.of());
    }

    /** Clears the soft-delete marker; users come back disabled for review. */
    @Transactional
    public void restore(Long tenantId, Long operatorId) {
        TenantJpaEntity tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + tenantId));
        if (tenant.getDeletedAt() == null) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "tenant.notDeleted");
        }
        tenant.setDeletedAt(null);
        tenant.setUpdatedAt(Instant.now());
        tenantRepository.save(tenant);
        userRepository.findAll().stream()
                .filter(u -> tenantId.equals(u.getTenantId()))
                .forEach(u -> {
                    u.setIsActive(false);
                    userRepository.save(u);
                });
        audit(operatorId, tenant, "TENANT_RESTORED", Map.of());
    }

    private TenantJpaEntity requireLive(Long tenantId) {
        TenantJpaEntity tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + tenantId));
        if (tenant.getDeletedAt() != null) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "tenant.alreadyDeleted");
        }
        return tenant;
    }

    private void audit(Long operatorId, TenantJpaEntity tenant, String eventType, Map<String, Object> extra) {
        try {
            Map<String, Object> details = new LinkedHashMap<>(extra);
            details.put("tenantId", tenant.getId());
            details.put("tenantName", tenant.getName());
            auditLogRepository.save(new AuditLog(
                    UUID.randomUUID().toString(),
                    eventType,
                    tenant.getId(),
                    operatorId,
                    eventType,
                    details,
                    Instant.now(),
                    null,
                    "PLATFORM_ADMIN"));
        } catch (Exception e) {
            log.error("Failed to audit {} for tenant {}", eventType, tenant.getId(), e);
        }
    }
}
