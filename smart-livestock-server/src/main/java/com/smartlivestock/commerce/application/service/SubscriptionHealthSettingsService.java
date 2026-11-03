package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.application.service.SubscriptionHealthSettingsProvider.HealthThresholds;
import com.smartlivestock.commerce.infrastructure.persistence.SpringDataSubscriptionHealthSettingsRepository;
import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionHealthSettingsJpaEntity;
import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Platform-level read/write for the NIX-324 banner tier settings
 * (V20261103100000, single-row table). Validates tier ordering on write,
 * records a {@code SUBSCRIPTION_HEALTH_SETTINGS_UPDATED} audit entry and
 * invalidates the read provider so the new tiers take effect immediately.
 */
@Service
@RequiredArgsConstructor
public class SubscriptionHealthSettingsService {

    private final SpringDataSubscriptionHealthSettingsRepository settingsRepository;
    private final SubscriptionHealthSettingsProvider settingsProvider;
    private final AuditLogRepository auditLogRepository;

    @Transactional(readOnly = true)
    public HealthThresholds get() {
        return settingsProvider.current();
    }

    @Transactional
    public HealthThresholds update(int warnDays, int cautionDays, int dangerDays,
                                   Long operatorId, String operatorRole) {
        if (warnDays <= 0 || cautionDays <= 0 || dangerDays <= 0
                || warnDays <= cautionDays || cautionDays <= dangerDays) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "commerce.healthSettings.invalidTiers", new Object[]{warnDays, cautionDays, dangerDays});
        }
        SubscriptionHealthSettingsJpaEntity entity = settingsRepository.findFirstByOrderByIdAsc()
                .orElseGet(SubscriptionHealthSettingsJpaEntity::new);
        entity.setWarnDays(warnDays);
        entity.setCautionDays(cautionDays);
        entity.setDangerDays(dangerDays);
        entity.setUpdatedBy(operatorId == null ? null : String.valueOf(operatorId));
        SubscriptionHealthSettingsJpaEntity saved = settingsRepository.save(entity);

        recordAudit("SUBSCRIPTION_HEALTH_SETTINGS_UPDATED", operatorId, operatorRole, saved);
        // New tiers must reach the evaluator on the very next verdict.
        settingsProvider.invalidate();
        return new HealthThresholds(saved.getWarnDays(), saved.getCautionDays(), saved.getDangerDays());
    }

    private void recordAudit(String action, Long operatorId, String operatorRole,
                             SubscriptionHealthSettingsJpaEntity saved) {
        auditLogRepository.save(new AuditLog(UUID.randomUUID().toString(), action,
                null, operatorId, action,
                Map.of("settingsId", saved.getId() == null ? "" : saved.getId(),
                        "warnDays", saved.getWarnDays(),
                        "cautionDays", saved.getCautionDays(),
                        "dangerDays", saved.getDangerDays(),
                        "operatorRole", operatorRole == null ? "" : operatorRole),
                Instant.now(), null, operatorRole));
    }
}
