package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.ranch.application.signal.SignalDtos.MapSignalResponse;
import com.smartlivestock.ranch.application.signal.SignalFarmAccessPolicy;
import com.smartlivestock.ranch.application.signal.SignalQueryService;
import com.smartlivestock.ranch.application.signal.SignalStreamTicketService;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.dto.FarmInfo;
import com.smartlivestock.ranch.infrastructure.signal.SignalStreamHub;
import com.smartlivestock.shared.common.GlobalExceptionHandler;
import com.smartlivestock.shared.common.MessageResolver;
import com.smartlivestock.shared.security.SwitchedContext;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Clock;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * The three signal endpoints share one access rule (SignalFarmAccessPolicy):
 * farm membership, or a super-admin switched context scoped to its tenant.
 * The real policy runs here with mocked repositories so the wiring — principal
 * to policy, tenant-less contexts, the localized refusal — is what gets tested.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SignalControllerTest {

    private static final Long FARM_ID = 1L;
    private static final Long TENANT_ID = 1L;
    private static final Long OTHER_TENANT_ID = 2L;
    private static final Long SUPER_ADMIN_ID = 9L;
    private static final Long OWNER_ID = 2L;
    private static final Long B2B_ADMIN_ID = 3L;

    private static final String STREAM_TICKET_PATH = "/api/v1/farms/1/signals/stream-ticket";
    private static final String MAP_PATH = "/api/v1/farms/1/signals/map";
    private static final String ENGLISH_REFUSAL = "No permission to access this farm's live signals";

    @Mock
    private SignalQueryService signalQueryService;
    @Mock
    private SignalStreamHub signalStreamHub;
    @Mock
    private UserFarmAssignmentRepository userFarmAssignmentRepository;
    @Mock
    private IdentityQueryPort identityQueryPort;

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        LocaleContextHolder.setLocale(Locale.ENGLISH);
        SignalStreamTicketService ticketService = new SignalStreamTicketService(
                Clock.systemUTC(), Duration.ofSeconds(30), Duration.ofMinutes(10));
        SignalController controller = new SignalController(
                signalQueryService,
                ticketService,
                signalStreamHub,
                new SignalFarmAccessPolicy(userFarmAssignmentRepository, identityQueryPort));
        ReloadableResourceBundleMessageSource messages = new ReloadableResourceBundleMessageSource();
        messages.setBasename("classpath:messages");
        messages.setDefaultEncoding("UTF-8");
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler(new MessageResolver(messages)))
                .build();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        TenantContext.clear();
        LocaleContextHolder.setLocale(null);
    }

    // ── stream ticket ───────────────────────────────────────────────

    @Test
    void farmMember_keepsGettingAStreamTicket() throws Exception {
        loginDirect(OWNER_ID, TENANT_ID, "ROLE_OWNER");
        when(userFarmAssignmentRepository.existsByUserIdAndFarmIdAndStatus(OWNER_ID, FARM_ID, "ACTIVE"))
                .thenReturn(true);

        mvc.perform(post(STREAM_TICKET_PATH))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("OK"))
                .andExpect(jsonPath("$.data.ticket").isNotEmpty())
                .andExpect(header().string("Set-Cookie", containsString("sl_signal_stream_")));
    }

    @Test
    void switchedContext_getsAStreamTicketForAFarmOfItsTenant() throws Exception {
        loginSwitched(SUPER_ADMIN_ID, TENANT_ID, "ROLE_OWNER");
        givenFarmBelongsTo(TENANT_ID);

        mvc.perform(post(STREAM_TICKET_PATH))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("OK"))
                .andExpect(jsonPath("$.data.ticket").isNotEmpty())
                .andExpect(header().string("Set-Cookie", containsString("sl_signal_stream_")));
    }

    @Test
    void switchedContext_isRefusedForAnotherTenantsFarm() throws Exception {
        loginSwitched(SUPER_ADMIN_ID, OTHER_TENANT_ID, "ROLE_OWNER");
        givenFarmBelongsTo(TENANT_ID);

        assertRefused(mvc.perform(post(STREAM_TICKET_PATH)));
    }

    @Test
    void switchedPlatformAdminContext_isTenantlessAndRefused() throws Exception {
        loginSwitched(SUPER_ADMIN_ID, null, "ROLE_PLATFORM_ADMIN");

        assertRefused(mvc.perform(post(STREAM_TICKET_PATH)));
        verifyNoInteractions(identityQueryPort);
    }

    @Test
    void rootSuperAdminToken_isRefused() throws Exception {
        loginDirect(SUPER_ADMIN_ID, null, "ROLE_SUPER_ADMIN");

        assertRefused(mvc.perform(post(STREAM_TICKET_PATH)));
    }

    @Test
    void b2bAdminWithoutMembership_isRefused() throws Exception {
        loginDirect(B2B_ADMIN_ID, TENANT_ID, "ROLE_B2B_ADMIN");

        assertRefused(mvc.perform(post(STREAM_TICKET_PATH)));
    }

    @Test
    void anonymous_isRefused() throws Exception {
        SecurityContextHolder.clearContext();
        TenantContext.clear();

        assertRefused(mvc.perform(post(STREAM_TICKET_PATH)));
    }

    // ── map signals ─────────────────────────────────────────────────

    @Test
    void switchedContext_readsMapSignals() throws Exception {
        loginSwitched(SUPER_ADMIN_ID, TENANT_ID, "ROLE_OWNER");
        givenFarmBelongsTo(TENANT_ID);
        when(signalQueryService.getMapSignals(FARM_ID, "0:0:0", true, SUPER_ADMIN_ID))
                .thenReturn(new MapSignalResponse(
                        FARM_ID, 1L, 1L, 1L, "1:1:1", false, false, false, false,
                        List.of(), List.of(), List.of()));

        mvc.perform(get(MAP_PATH).param("cursor", "0:0:0").param("includeGeometry", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("OK"))
                .andExpect(jsonPath("$.data.farmId").value(1))
                .andExpect(jsonPath("$.data.cursor").value("1:1:1"));
    }

    @Test
    void mapSignals_handsTheCallerIdentityToTheQueryService() throws Exception {
        // /map is guarded inside SignalQueryService (the policy runs there),
        // so the controller's job is to pass the authenticated user through.
        loginDirect(B2B_ADMIN_ID, TENANT_ID, "ROLE_B2B_ADMIN");
        when(signalQueryService.getMapSignals(FARM_ID, "0:0:0", true, B2B_ADMIN_ID))
                .thenThrow(SignalFarmAccessPolicy.forbidden());

        // The service's refusal must surface as the same localized 403 as the
        // controller-guarded ticket endpoint.
        assertRefused(mvc.perform(get(MAP_PATH).param("cursor", "0:0:0").param("includeGeometry", "true")));
    }

    // ── helpers ──────────────────────────────────────────────────────

    private void assertRefused(ResultActions result) throws Exception {
        result.andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"))
                .andExpect(jsonPath("$.message").value(ENGLISH_REFUSAL));
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
