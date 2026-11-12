package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.FenceTrackDraftService;
import com.smartlivestock.ranch.application.FenceTrackParseService;
import com.smartlivestock.ranch.application.command.CreateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.application.dto.TrackDraftCandidatesDto;
import com.smartlivestock.ranch.application.dto.TrackDraftSourceDto;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.dto.FarmInfo;
import com.smartlivestock.ranch.domain.port.dto.TrackerCandidate;
import com.smartlivestock.shared.common.GlobalExceptionHandler;
import com.smartlivestock.shared.common.MessageResolver;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.Locale;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Controller tests for FenceController's authorization and request-shaping
 * behavior around the fence track-draft endpoints (plan Task 2) and the
 * metadata-carrying fence creation (plan Task 1):
 * <ul>
 *     <li>method-level role guard: OWNER passes, non-manager roles (WORKER)
 *     are denied 403 before any service/farm-ownership work happens;</li>
 *     <li>farm-ownership guard: unknown farm 404, cross-tenant farm 403;</li>
 *     <li>POST /fences passes the {@code generationMetadata} body key through
 *     to {@link CreateFenceCommand} (ArgumentCaptor) and echoes it back.</li>
 * </ul>
 * <p>
 * Assembly note: FenceController's role guard lives in {@code @PreAuthorize},
 * which plain standalone MockMvc does NOT evaluate (see
 * {@code EstrusFeedbackControllerTest} for the standalone precedent and its
 * limitation note). To assert the guard behaviorally (403 on a non-manager
 * role), the controller bean is instantiated inside a minimal Spring context
 * with {@code @EnableMethodSecurity} so it gets the authorization interceptor
 * proxied on, then that proxied bean is plugged into standalone MockMvc.
 * Services are Mockito mocks — no database, no filter chain, no CSRF.
 * Request validation branches (days range, malformed track-draft body) are
 * controller-owned and also covered here.
 */
@ExtendWith(MockitoExtension.class)
class FenceControllerTest {

    private static final Long FARM_ID = 7L;
    private static final Long TENANT_ID = 42L;
    private static final String BASE = "/api/v1/farms/" + FARM_ID + "/fences";

    @Mock
    private FenceApplicationService fenceApplicationService;

    @Mock
    private FenceTrackParseService fenceTrackParseService;

    @Mock
    private FenceTrackDraftService fenceTrackDraftService;

    @Mock
    private IdentityQueryPort identityQueryPort;

    private AnnotationConfigApplicationContext context;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        LocaleContextHolder.setLocale(Locale.ENGLISH); // stable message assertions

        context = new AnnotationConfigApplicationContext();
        context.register(MethodSecurityConfiguration.class);
        context.registerBean(FenceApplicationService.class, () -> fenceApplicationService);
        context.registerBean(FenceTrackParseService.class, () -> fenceTrackParseService);
        context.registerBean(FenceTrackDraftService.class, () -> fenceTrackDraftService);
        context.registerBean(IdentityQueryPort.class, () -> identityQueryPort);
        context.registerBean(FenceController.class, () -> new FenceController(
                fenceApplicationService, fenceTrackParseService,
                fenceTrackDraftService, identityQueryPort));
        context.refresh();

        GlobalExceptionHandler advice = new GlobalExceptionHandler(
                new MessageResolver(testMessageSource()));

        // Use the PROXIED bean so @PreAuthorize actually fires (standalone
        // MockMvc alone would skip method-security interception entirely).
        mvc = MockMvcBuilders.standaloneSetup(context.getBean(FenceController.class))
                .setControllerAdvice(advice)
                .build();
    }

    @AfterEach
    void tearDown() {
        context.close();
        TenantContext.clear();
        SecurityContextHolder.clearContext();
        LocaleContextHolder.setLocale(null);
    }

    private void loginAs(Long userId, String... roles) {
        SecurityContextHolder.getContext().setAuthentication(
                new TestingAuthenticationToken(userId, "n/a", roles));
    }

    private void givenFarmOwned() {
        when(identityQueryPort.findFarmById(FARM_ID))
                .thenReturn(Optional.of(new FarmInfo(FARM_ID, TENANT_ID, "示范牧场", null, null)));
    }

    // ── OWNER passes the two-level guard ─────────────────────────────

    @Nested
    class OwnerAllowed {

        @Test
        void ownerListsTrackDraftCandidates() throws Exception {
            loginAs(9L, "ROLE_OWNER");
            givenFarmOwned();
            when(fenceTrackDraftService.candidates(FARM_ID, 30))
                    .thenReturn(new TrackDraftCandidatesDto(
                            List.of(new TrackerCandidate(11L, "TRK-001", "NL-0001",
                                    Instant.parse("2026-11-10T02:00:00Z"), 1234L)),
                            new TrackDraftCandidatesDto.FenceQuota(3, 10)));

            mvc.perform(get(BASE + "/track-draft/candidates").param("days", "30"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.code").value("OK"))
                    .andExpect(jsonPath("$.data.devices[0].deviceId").value(11))
                    .andExpect(jsonPath("$.data.devices[0].name").value("TRK-001"))
                    .andExpect(jsonPath("$.data.devices[0].earTag").value("NL-0001"))
                    .andExpect(jsonPath("$.data.devices[0].lastFixAt").exists())
                    .andExpect(jsonPath("$.data.devices[0].pointCount").value(1234))
                    .andExpect(jsonPath("$.data.fenceQuota.current").value(3))
                    .andExpect(jsonPath("$.data.fenceQuota.limit").value(10));

            verify(fenceTrackDraftService).candidates(FARM_ID, 30);
        }

        @Test
        void ownerLoadsTrackDraftSource() throws Exception {
            loginAs(9L, "ROLE_OWNER");
            givenFarmOwned();
            Instant from = OffsetDateTime.parse("2026-10-13T00:00:00+08:00").toInstant();
            Instant to = OffsetDateTime.parse("2026-11-12T00:00:00+08:00").toInstant();
            when(fenceTrackDraftService.source(FARM_ID, List.of(11L, 12L), from, to))
                    .thenReturn(new TrackDraftSourceDto(
                            List.of(new TrackDraftSourceDto.Point(
                                    new BigDecimal("37.123456"), new BigDecimal("122.654321"),
                                    12.5, Instant.parse("2026-10-20T01:30:00Z"))),
                            2L,
                            List.of(new TrackDraftSourceDto.DeviceRaw(11L, 2L)),
                            false,
                            1L));

            mvc.perform(post(BASE + "/track-draft/source")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"deviceIds":[11,12],
                                     "startTime":"2026-10-13T00:00:00+08:00",
                                     "endTime":"2026-11-12T00:00:00+08:00"}"""))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.code").value("OK"))
                    .andExpect(jsonPath("$.data.totalRaw").value(2))
                    .andExpect(jsonPath("$.data.truncated").value(false))
                    .andExpect(jsonPath("$.data.sampledStride").value(1))
                    .andExpect(jsonPath("$.data.points[0].lat").value(37.123456))
                    .andExpect(jsonPath("$.data.points[0].lng").value(122.654321))
                    .andExpect(jsonPath("$.data.points[0].accuracyM").value(12.5))
                    .andExpect(jsonPath("$.data.points[0].recordedAt").exists())
                    .andExpect(jsonPath("$.data.perDevice[0].deviceId").value(11))
                    .andExpect(jsonPath("$.data.perDevice[0].raw").value(2));

            verify(fenceTrackDraftService).source(FARM_ID, List.of(11L, 12L), from, to);
        }

        /**
         * The controller must pass the optional generationMetadata body key
         * through to the command unchanged (plan Task 1) and echo it in the
         * FenceDto response.
         */
        @Test
        void ownerCreatesFenceWithGenerationMetadata() throws Exception {
            loginAs(9L, "ROLE_OWNER");
            givenFarmOwned();
            Map<String, Object> metadata = Map.of(
                    "source", "DEVICE_TRACK",
                    "deviceIds", List.of(11, 12),
                    "totalRawPoints", 5230);
            when(fenceApplicationService.createFence(org.mockito.ArgumentMatchers.any()))
                    .thenReturn(new FenceDto(101L, FARM_ID, "北围栏",
                            List.of(new GpsCoordinate(new BigDecimal("37.123"), new BigDecimal("122.654"))),
                            "#33CC66", true, 1, "GRASS", 0, metadata));

            mvc.perform(post(BASE)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name":"北围栏",
                                     "vertices":[{"lat":37.123,"lng":122.654}],
                                     "color":"#33CC66",
                                     "fenceType":"GRASS",
                                     "generationMetadata":{"source":"DEVICE_TRACK",
                                                           "deviceIds":[11,12],
                                                           "totalRawPoints":5230}}"""))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.code").value("OK"))
                    .andExpect(jsonPath("$.data.id").value(101))
                    .andExpect(jsonPath("$.data.name").value("北围栏"))
                    .andExpect(jsonPath("$.data.vertices[0].lat").value(37.123))
                    .andExpect(jsonPath("$.data.generationMetadata.source").value("DEVICE_TRACK"));

            ArgumentCaptor<CreateFenceCommand> captor =
                    ArgumentCaptor.forClass(CreateFenceCommand.class);
            verify(fenceApplicationService).createFence(captor.capture());
            CreateFenceCommand command = captor.getValue();
            assertThat(command.farmId()).isEqualTo(FARM_ID);
            assertThat(command.name()).isEqualTo("北围栏");
            assertThat(command.color()).isEqualTo("#33CC66");
            assertThat(command.fenceType()).isEqualTo("GRASS");
            assertThat(command.vertices()).hasSize(1);
            assertThat(command.vertices().get(0).latitude()).isEqualTo(new BigDecimal("37.123"));
            assertThat(command.vertices().get(0).longitude()).isEqualTo(new BigDecimal("122.654"));
            assertThat(command.generationMetadata()).containsEntry("source", "DEVICE_TRACK");
            assertThat(command.generationMetadata().get("deviceIds")).isEqualTo(List.of(11, 12));
            assertThat(command.generationMetadata().get("totalRawPoints")).isEqualTo(5230);
        }
    }

    // ── Non-manager roles are denied before any farm/service work ────

    @Nested
    class MethodSecurityGuard {

        @Test
        void workerIsDeniedTrackDraftCandidates() throws Exception {
            loginAs(9L, "ROLE_WORKER");

            mvc.perform(get(BASE + "/track-draft/candidates").param("days", "30"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));

            verifyNoInteractions(fenceTrackDraftService, identityQueryPort);
        }

        @Test
        void workerIsDeniedTrackDraftSource() throws Exception {
            loginAs(9L, "ROLE_WORKER");

            mvc.perform(post(BASE + "/track-draft/source")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"deviceIds":[11],
                                     "startTime":"2026-10-13T00:00:00+08:00",
                                     "endTime":"2026-11-12T00:00:00+08:00"}"""))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));

            verifyNoInteractions(fenceTrackDraftService, identityQueryPort);
        }

        @Test
        void workerIsDeniedFenceCreation() throws Exception {
            loginAs(9L, "ROLE_WORKER");

            mvc.perform(post(BASE)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name":"北围栏",
                                     "vertices":[{"lat":37.123,"lng":122.654}],
                                     "generationMetadata":{"source":"DEVICE_TRACK"}}"""))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));

            verifyNoInteractions(fenceApplicationService, identityQueryPort);
        }
    }

    // ── Farm-ownership guard (runs after the role guard passes) ──────

    @Nested
    class FarmOwnershipGuard {

        @Test
        void unknownFarmYieldsNotFound() throws Exception {
            loginAs(9L, "ROLE_OWNER");
            when(identityQueryPort.findFarmById(FARM_ID)).thenReturn(Optional.empty());

            mvc.perform(get(BASE + "/track-draft/candidates").param("days", "30"))
                    .andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"));

            verifyNoInteractions(fenceTrackDraftService);
        }

        @Test
        void crossTenantFarmYieldsForbidden() throws Exception {
            loginAs(9L, "ROLE_OWNER");
            when(identityQueryPort.findFarmById(FARM_ID))
                    .thenReturn(Optional.of(new FarmInfo(FARM_ID, 999L, "别家牧场", null, null)));
            TenantContext.setCurrentTenant(TENANT_ID);

            mvc.perform(get(BASE + "/track-draft/candidates").param("days", "30"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));

            verifyNoInteractions(fenceTrackDraftService);
        }
    }

    // ── Controller-owned request validation ──────────────────────────

    @Nested
    class RequestValidation {

        @Test
        void candidatesDaysOutOfRangeIsRejectedAs400() throws Exception {
            loginAs(9L, "ROLE_OWNER");
            givenFarmOwned();

            mvc.perform(get(BASE + "/track-draft/candidates").param("days", "31"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

            verifyNoInteractions(fenceTrackDraftService);
        }

        @Test
        void trackDraftSourceWithoutDeviceIdsIsRejectedAs400() throws Exception {
            loginAs(9L, "ROLE_OWNER");
            givenFarmOwned();

            mvc.perform(post(BASE + "/track-draft/source")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"startTime":"2026-10-13T00:00:00+08:00",
                                     "endTime":"2026-11-12T00:00:00+08:00"}"""))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

            verifyNoInteractions(fenceTrackDraftService);
        }
    }

    // ── Test assembly ────────────────────────────────────────────────

    /**
     * Minimal method-security activation: gives the controller bean the same
     * {@code @PreAuthorize} interceptor the production {@code SecurityConfig}
     * would install, without pulling in the JWT/API-key filter chain.
     */
    @Configuration(proxyBeanMethods = false)
    @EnableMethodSecurity
    static class MethodSecurityConfiguration {
    }

    private static ReloadableResourceBundleMessageSource testMessageSource() {
        ReloadableResourceBundleMessageSource source = new ReloadableResourceBundleMessageSource();
        source.setBasename("classpath:messages");
        source.setDefaultEncoding("UTF-8");
        source.setUseCodeAsDefaultMessage(true);
        return source;
    }
}
