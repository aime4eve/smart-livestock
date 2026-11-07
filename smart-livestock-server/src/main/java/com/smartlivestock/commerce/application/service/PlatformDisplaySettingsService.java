package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.LockedTilePolicy;
import com.smartlivestock.commerce.domain.model.PlatformDisplaySettings;
import com.smartlivestock.commerce.domain.repository.PlatformDisplaySettingsRepository;
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
 * Platform-level read/write for the NIX-389 locked-tile presentation policy
 * (V20261107100000, single-row table). Value validation happens here and in
 * the admin controller (same double-guard shape as
 * SubscriptionHealthSettings), a successful update records a
 * {@code PLATFORM_DISPLAY_SETTINGS_UPDATED} audit entry and invalidates the
 * read provider so the new policy takes effect on the very next request.
 */
@Service
@RequiredArgsConstructor
public class PlatformDisplaySettingsService {

    private final PlatformDisplaySettingsRepository settingsRepository;
    private final PlatformDisplaySettingsProvider settingsProvider;
    private final AuditLogRepository auditLogRepository;

    /**
     * Current policy. Missing row / read failure falls back to
     * {@link LockedTilePolicy#SHOW_LOCKED} inside the provider.
     */
    @Transactional(readOnly = true)
    public LockedTilePolicy getLockedTilePolicy() {
        return settingsProvider.current();
    }

    /**
     * Persist a new policy and return it. Invalid values are rejected with a
     * {@code VALIDATION_ERROR} (value domain {SHOW_LOCKED, HIDE}); the DB
     * CHECK constraint is the second line of defence.
     */
    @Transactional
    public LockedTilePolicy updateLockedTilePolicy(LockedTilePolicy policy, Long operatorId, String operatorRole) {
        if (policy == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "commerce.displaySettings.invalidPolicy", new Object[]{(Object) null});
        }
        PlatformDisplaySettings saved = settingsRepository.save(new PlatformDisplaySettings(
                null, policy, null, operatorId == null ? null : String.valueOf(operatorId)));

        auditLogRepository.save(new AuditLog(UUID.randomUUID().toString(),
                "PLATFORM_DISPLAY_SETTINGS_UPDATED", null, operatorId,
                "PLATFORM_DISPLAY_SETTINGS_UPDATED",
                Map.of("settingsId", saved.getId() == null ? "" : saved.getId(),
                        "lockedTilePolicy", saved.getLockedTilePolicy().name(),
                        "operatorRole", operatorRole == null ? "" : operatorRole),
                Instant.now(), null, operatorRole));

        // New policy must reach the overview assembly on the very next request.
        settingsProvider.invalidate();
        return saved.getLockedTilePolicy();
    }

    /** Parse a raw request value into the enum, rejecting anything outside the domain. */
    public static LockedTilePolicy parsePolicy(String raw) {
        try {
            return LockedTilePolicy.valueOf(raw.trim().toUpperCase());
        } catch (Exception e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "commerce.displaySettings.invalidPolicy", new Object[]{String.valueOf(raw)});
        }
    }
}
