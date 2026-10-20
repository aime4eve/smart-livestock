package com.smartlivestock.identity.application;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.identity.application.command.SwitchContextCommand;
import com.smartlivestock.identity.application.dto.AuthTokenDto;
import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.Tenant;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataFarmRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataTenantRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.JwtTokenProvider;
import com.smartlivestock.shared.security.PasswordHasher;
import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Super-admin context switch gate matrix (design 2026-10-19 §4.3) and the
 * refresh identity-synthesis rule (§4.2). Uses a real JwtTokenProvider so
 * token/claim assertions exercise the actual signing path.
 */
class AuthApplicationServiceSwitchContextTest {

    private static final String SECRET = "unit-test-secret-0123456789abcdef0123456789abcdef";

    private final UserRepository userRepository = mock(UserRepository.class);
    private final PasswordHasher passwordHasher = mock(PasswordHasher.class);
    private final JwtTokenProvider jwtTokenProvider = new JwtTokenProvider(SECRET, 3600000L);
    private final TenantRepository tenantRepository = mock(TenantRepository.class);
    private final SpringDataTenantRepository springDataTenantRepository = mock(SpringDataTenantRepository.class);
    private final SpringDataFarmRepository springDataFarmRepository = mock(SpringDataFarmRepository.class);
    private final SubscriptionRepository subscriptionRepository = mock(SubscriptionRepository.class);
    private final AuditLogRepository auditLogRepository = mock(AuditLogRepository.class);

    private AuthApplicationService service;

    private final User superAdmin = mock(User.class);
    private final Tenant tenant = mock(Tenant.class);
    private final Subscription subscription = mock(Subscription.class);

    @BeforeEach
    void setUp() {
        service = new AuthApplicationService(userRepository, passwordHasher, jwtTokenProvider,
                tenantRepository, springDataTenantRepository, springDataFarmRepository,
                subscriptionRepository, auditLogRepository);

        when(superAdmin.getId()).thenReturn(6L);
        when(superAdmin.getRole()).thenReturn(Role.SUPER_ADMIN);
        when(superAdmin.getTenantId()).thenReturn(null);
        when(superAdmin.isMustChangePassword()).thenReturn(false);
        when(superAdmin.isActive()).thenReturn(true);
        when(superAdmin.getName()).thenReturn("超级管理员");
        when(superAdmin.getAccount()).thenReturn("Admin@hkt.com");

        when(tenant.getId()).thenReturn(2L);
        when(tenant.isDeleted()).thenReturn(false);

        when(userRepository.findById(6L)).thenReturn(Optional.of(superAdmin));
        when(tenantRepository.findById(2L)).thenReturn(Optional.of(tenant));
        // Default: healthy active subscription (not trial-expired).
        when(subscription.getStatus()).thenReturn(SubscriptionStatus.ACTIVE);
        when(subscriptionRepository.findByTenantId(2L)).thenReturn(Optional.of(subscription));
    }

    @Test
    void switch_nonSuperAdminCaller_forbidden() {
        when(superAdmin.getRole()).thenReturn(Role.OWNER);
        assertThatThrownBy(() -> service.switchContext(6L, new SwitchContextCommand("PLATFORM_ADMIN", null)))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.AUTH_FORBIDDEN));
    }

    @Test
    void switch_passwordChangeLock_cannotBeBypassed() {
        // /api/v1/auth/** is on the password-change whitelist; the switch
        // itself must re-check the lock (design §4.8).
        when(superAdmin.isMustChangePassword()).thenReturn(true);
        assertThatThrownBy(() -> service.switchContext(6L, new SwitchContextCommand("PLATFORM_ADMIN", null)))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.PASSWORD_CHANGE_REQUIRED));
    }

    @Test
    void switch_nonSelectableRoles_rejected() {
        for (String role : new String[]{"API_CONSUMER", "SUPER_ADMIN", "hacker"}) {
            assertThatThrownBy(() -> service.switchContext(6L, new SwitchContextCommand(role, null)))
                    .isInstanceOf(ApiException.class)
                    .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        }
    }

    @Test
    void switch_tenantScopedRoleWithoutTenant_rejected() {
        assertThatThrownBy(() -> service.switchContext(6L, new SwitchContextCommand("OWNER", null)))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
    }

    @Test
    void switch_missingOrDeletedTenant_notFound() {
        when(tenantRepository.findById(99L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.switchContext(6L, new SwitchContextCommand("OWNER", 99L)))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND));

        when(tenant.isDeleted()).thenReturn(true);
        assertThatThrownBy(() -> service.switchContext(6L, new SwitchContextCommand("OWNER", 2L)))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND));
    }

    @Test
    void switch_trialExpiredTenant_rejected() {
        when(subscription.getStatus()).thenReturn(SubscriptionStatus.FREE);
        assertThatThrownBy(() -> service.switchContext(6L, new SwitchContextCommand("OWNER", 2L)))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.LICENSE_EXPIRED));

        when(subscription.getStatus()).thenReturn(SubscriptionStatus.TRIAL);
        when(subscription.getTrialEndsAt()).thenReturn(Instant.now().minusSeconds(60));
        assertThatThrownBy(() -> service.switchContext(6L, new SwitchContextCommand("OWNER", 2L)))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.LICENSE_EXPIRED));
    }

    @Test
    void switch_disabledTenant_isEnterable_withAudit() {
        // Ruling 2026-10-19 #1: disabled tenants stay enterable for triage.
        AuthTokenDto result = service.switchContext(6L, new SwitchContextCommand("OWNER", 2L));
        assertThat(result.impersonated()).isTrue();
        assertThat(result.user().role()).isEqualTo("OWNER");
        assertThat(result.user().tenantId()).isEqualTo(2L);
        verify(auditLogRepository).save(any(AuditLog.class));

        Claims claims = jwtTokenProvider.parseToken(result.accessToken());
        assertThat(claims.get("role")).isEqualTo("OWNER");
        assertThat(claims.get("tid")).isEqualTo(2);
        assertThat(claims.getSubject()).isEqualTo("6");
        @SuppressWarnings("unchecked")
        Map<String, Object> act = (Map<String, Object>) claims.get("act");
        assertThat(act.get("role")).isEqualTo("SUPER_ADMIN");
    }

    @Test
    void switch_platformAdmin_tenantlessToken() {
        AuthTokenDto result = service.switchContext(6L, new SwitchContextCommand("PLATFORM_ADMIN", null));
        Claims claims = jwtTokenProvider.parseToken(result.accessToken());
        assertThat(claims.get("role")).isEqualTo("PLATFORM_ADMIN");
        assertThat(claims.get("tid")).isNull();
        assertThat(claims.get("act")).isNotNull();
        assertThat(result.user().tenantId()).isNull();
    }

    @Test
    void refresh_contextToken_returnsEffectiveIdentity() {
        AuthTokenDto switched = service.switchContext(6L, new SwitchContextCommand("B2B_ADMIN", 2L));
        AuthTokenDto refreshed = service.refresh(switched.accessToken());

        assertThat(refreshed.impersonated()).isTrue();
        assertThat(refreshed.user().role()).isEqualTo("B2B_ADMIN");
        assertThat(refreshed.user().tenantId()).isEqualTo(2L);
        assertThat(refreshed.user().account()).isEqualTo("Admin@hkt.com");

        Claims claims = jwtTokenProvider.parseToken(refreshed.accessToken());
        assertThat(claims.get("role")).isEqualTo("B2B_ADMIN");
        @SuppressWarnings("unchecked")
        Map<String, Object> act = (Map<String, Object>) claims.get("act");
        assertThat(act.get("role")).isEqualTo("SUPER_ADMIN");
    }

    @Test
    void refresh_plainToken_returnsStoredIdentity() {
        String plain = jwtTokenProvider.generateToken(6L, null, "SUPER_ADMIN");
        AuthTokenDto refreshed = service.refresh(plain);
        assertThat(refreshed.impersonated()).isFalse();
        assertThat(refreshed.user().role()).isEqualTo("SUPER_ADMIN");
        assertThat(refreshed.user().tenantId()).isNull();
    }
}
