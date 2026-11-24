package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.dto.FarmInfo;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.SwitchedContext;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.context.support.ResourceBundleMessageSource;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Locale;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Who may read a farm's live signals. Farm membership (an ACTIVE
 * user_farm_assignments row) is the original rule; a super-admin switched
 * context is scoped by its tenant instead, because the context entry creates
 * no per-farm membership rows (design 2026-10-19).
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SignalFarmAccessPolicyTest {

    private static final Long FARM_ID = 1L;
    private static final Long TENANT_ID = 1L;
    private static final Long OTHER_TENANT_ID = 2L;
    private static final Long SUPER_ADMIN_ID = 9L;
    private static final Long MEMBER_ID = 2L;

    @Mock
    private UserFarmAssignmentRepository userFarmAssignmentRepository;
    @Mock
    private IdentityQueryPort identityQueryPort;

    private SignalFarmAccessPolicy policy;

    @BeforeEach
    void setUp() {
        policy = new SignalFarmAccessPolicy(userFarmAssignmentRepository, identityQueryPort);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        TenantContext.clear();
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    void farmMemberWithActiveAssignmentIsAllowedWithoutAnyFarmLookup() {
        loginDirect(MEMBER_ID, TENANT_ID, "ROLE_OWNER");
        whenMember(MEMBER_ID, true);

        assertThatCode(() -> policy.requireFarmAccess(FARM_ID, MEMBER_ID))
                .doesNotThrowAnyException();

        verifyNoInteractions(identityQueryPort);
    }

    @Test
    void switchedContextReachesEveryFarmOfItsTenant() {
        loginSwitched(SUPER_ADMIN_ID, TENANT_ID, "ROLE_OWNER");
        givenFarmBelongsTo(TENANT_ID);

        assertThatCode(() -> policy.requireFarmAccess(FARM_ID, SUPER_ADMIN_ID))
                .doesNotThrowAnyException();
    }

    @Test
    void switchedContextIsRefusedForAnotherTenantsFarm() {
        loginSwitched(SUPER_ADMIN_ID, TENANT_ID, "ROLE_OWNER");
        givenFarmBelongsTo(OTHER_TENANT_ID);

        assertRefused(SUPER_ADMIN_ID);
    }

    @Test
    void switchedContextIsRefusedForUnknownFarm() {
        loginSwitched(SUPER_ADMIN_ID, TENANT_ID, "ROLE_OWNER");
        when(identityQueryPort.findFarmById(FARM_ID)).thenReturn(Optional.empty());

        assertRefused(SUPER_ADMIN_ID);
    }

    @Test
    void switchedPlatformAdminContextIsTenantlessAndRefused() {
        loginSwitched(SUPER_ADMIN_ID, null, "ROLE_PLATFORM_ADMIN");

        assertRefused(SUPER_ADMIN_ID);

        // No tenant means nothing to scope by: the farm is not even looked up.
        verifyNoInteractions(identityQueryPort);
    }

    @ParameterizedTest(name = "direct session {0} in tenant {1} without membership")
    @CsvSource(value = {
            "ROLE_B2B_ADMIN|1",
            "ROLE_OWNER|1",
            "ROLE_SUPER_ADMIN|",
            "ROLE_PLATFORM_ADMIN|"
    }, delimiter = '|')
    void directSessionWithoutMembershipStaysRefused(String role, Long tenantId) {
        loginDirect(SUPER_ADMIN_ID, tenantId, role);

        assertRefused(SUPER_ADMIN_ID);

        // Tenant scoping is a switched-context privilege only.
        verifyNoInteractions(identityQueryPort);
    }

    @Test
    void missingUserIsRefusedBeforeAnyLookup() {
        SecurityContextHolder.clearContext();
        TenantContext.clear();

        assertRefused(null);

        verifyNoInteractions(userFarmAssignmentRepository, identityQueryPort);
    }

    @Test
    void apiKeyPrincipalIsRefusedEvenWhenItsIdCollidesWithAMember() {
        // ApiKeyAuthFilter authenticates as api_keys.id — a Long the membership
        // check would mistake for a user id (seeded key 2 collides with user 2,
        // an ACTIVE farm member). The request attribute is the only tell.
        loginDirect(2L, TENANT_ID, "ROLE_ADMIN");
        whenMember(2L, true);
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setAttribute(com.smartlivestock.shared.security.ApiKeyAuthFilter.ATTR_API_KEY,
                new Object());
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));

        assertRefused(2L);

        // Refusal happens before the colliding membership lookup.
        verifyNoInteractions(userFarmAssignmentRepository, identityQueryPort);
    }

    @Test
    void superAdminWithAMembershipRowIsStillRefusedWithoutASwitchedContext() {
        // POST /farms/{id}/members can grant the super admin account a
        // membership row; the root token must stay refused regardless.
        loginDirect(SUPER_ADMIN_ID, TENANT_ID, "ROLE_SUPER_ADMIN");
        whenMember(SUPER_ADMIN_ID, true);

        assertRefused(SUPER_ADMIN_ID);
    }

    @Test
    void refusalIsTheSharedLocalizedMessageKey() {
        assertThatThrownBy(() -> policy.requireFarmAccess(FARM_ID, MEMBER_ID))
                .isInstanceOf(ApiException.class)
                .hasMessage(SignalFarmAccessPolicy.MESSAGE_KEY)
                .hasFieldOrPropertyWithValue("code", ErrorCode.AUTH_FORBIDDEN);
    }

    @Test
    void refusalMessageExistsInDefaultChineseAndEnglishBundles() {
        ResourceBundleMessageSource messages = new ResourceBundleMessageSource();
        messages.setBasename("messages");
        messages.setDefaultEncoding("UTF-8");

        // The default bundle carries the key too (messages.properties).
        assertThat(messages.getMessage(SignalFarmAccessPolicy.MESSAGE_KEY, null, Locale.ROOT))
                .isEqualTo("无权访问该牧场信号");
        assertThat(messages.getMessage(SignalFarmAccessPolicy.MESSAGE_KEY, null, Locale.SIMPLIFIED_CHINESE))
                .isEqualTo("无权访问该牧场信号");
        assertThat(messages.getMessage(SignalFarmAccessPolicy.MESSAGE_KEY, null, Locale.ENGLISH))
                .isEqualTo("No permission to access this farm's live signals");
    }

    private void assertRefused(Long userId) {
        assertThatThrownBy(() -> policy.requireFarmAccess(FARM_ID, userId))
                .isInstanceOf(ApiException.class)
                .hasMessage(SignalFarmAccessPolicy.MESSAGE_KEY)
                .hasFieldOrPropertyWithValue("code", ErrorCode.AUTH_FORBIDDEN);
    }

    private void whenMember(Long userId, boolean active) {
        when(userFarmAssignmentRepository.existsByUserIdAndFarmIdAndStatus(userId, FARM_ID, "ACTIVE"))
                .thenReturn(active);
    }

    private void givenFarmBelongsTo(Long tenantId) {
        when(identityQueryPort.findFarmById(FARM_ID))
                .thenReturn(Optional.of(new FarmInfo(FARM_ID, tenantId, "HKT Main Ranch", null, null)));
    }

    /** A user logged in directly: role + tenant, no switched-context marker. */
    private void loginDirect(Long userId, Long tenantId, String... roles) {
        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken(userId, "n/a", roles);
        SecurityContextHolder.getContext().setAuthentication(authentication);
        TenantContext.setCurrentTenant(tenantId);
    }

    /** What JwtAuthenticationFilter builds for a token carrying the act claim. */
    private void loginSwitched(Long superAdminId, Long tenantId, String... roles) {
        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken(superAdminId, "n/a", roles);
        authentication.setDetails(new SwitchedContext.Marker(superAdminId));
        SecurityContextHolder.getContext().setAuthentication(authentication);
        TenantContext.setCurrentTenant(tenantId);
    }
}
