package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.LockedTilePolicy;
import com.smartlivestock.commerce.domain.model.PlatformDisplaySettings;
import com.smartlivestock.commerce.domain.repository.PlatformDisplaySettingsRepository;
import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Write-side behaviour of the NIX-389 policy service: value-domain
 * validation, audit trail, provider invalidation and the raw-value parser.
 */
@ExtendWith(MockitoExtension.class)
class PlatformDisplaySettingsServiceTest {

    @Mock
    private PlatformDisplaySettingsRepository settingsRepository;
    @Mock
    private PlatformDisplaySettingsProvider settingsProvider;
    @Mock
    private AuditLogRepository auditLogRepository;

    private PlatformDisplaySettingsService service;

    @BeforeEach
    void setUp() {
        service = new PlatformDisplaySettingsService(settingsRepository, settingsProvider, auditLogRepository);
    }

    @Test
    @DisplayName("getLockedTilePolicy delegates to the provider (fallback included)")
    void get_delegatesToProvider() {
        when(settingsProvider.current()).thenReturn(LockedTilePolicy.SHOW_LOCKED);
        assertThat(service.getLockedTilePolicy()).isEqualTo(LockedTilePolicy.SHOW_LOCKED);

        when(settingsProvider.current()).thenReturn(LockedTilePolicy.HIDE);
        assertThat(service.getLockedTilePolicy()).isEqualTo(LockedTilePolicy.HIDE);
    }

    @Test
    @DisplayName("update persists the policy, records an audit entry and invalidates the cache")
    void update_persistsAuditsAndInvalidates() {
        when(settingsRepository.save(any(PlatformDisplaySettings.class)))
                .thenAnswer(inv -> {
                    PlatformDisplaySettings s = inv.getArgument(0);
                    return new PlatformDisplaySettings(1L, s.getLockedTilePolicy(), null, s.getUpdatedBy());
                });

        LockedTilePolicy updated = service.updateLockedTilePolicy(LockedTilePolicy.HIDE, 42L, "ROLE_PLATFORM_ADMIN");

        assertThat(updated).isEqualTo(LockedTilePolicy.HIDE);
        verify(settingsRepository).save(any(PlatformDisplaySettings.class));
        verify(auditLogRepository).save(any(AuditLog.class));
        verify(settingsProvider).invalidate();
    }

    @Test
    @DisplayName("update with a null policy is rejected with VALIDATION_ERROR")
    void update_nullPolicy_rejected() {
        assertThatThrownBy(() -> service.updateLockedTilePolicy(null, 42L, "ROLE_PLATFORM_ADMIN"))
                .isInstanceOfSatisfying(ApiException.class,
                        e -> assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        verify(settingsRepository, org.mockito.Mockito.never()).save(any());
    }

    @Test
    @DisplayName("parsePolicy accepts case-insensitive values from the domain")
    void parsePolicy_acceptsKnownValues() {
        assertThat(PlatformDisplaySettingsService.parsePolicy("HIDE")).isEqualTo(LockedTilePolicy.HIDE);
        assertThat(PlatformDisplaySettingsService.parsePolicy("show_locked"))
                .isEqualTo(LockedTilePolicy.SHOW_LOCKED);
        assertThat(PlatformDisplaySettingsService.parsePolicy(" Show_Locked "))
                .isEqualTo(LockedTilePolicy.SHOW_LOCKED);
    }

    @Test
    @DisplayName("parsePolicy rejects anything outside the value domain")
    void parsePolicy_rejectsUnknownValues() {
        assertThatThrownBy(() -> PlatformDisplaySettingsService.parsePolicy("EVERYTHING_OPEN"))
                .isInstanceOfSatisfying(ApiException.class,
                        e -> assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        assertThatThrownBy(() -> PlatformDisplaySettingsService.parsePolicy(null))
                .isInstanceOfSatisfying(ApiException.class,
                        e -> assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
    }
}
