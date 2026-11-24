package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * End-to-end farm-signal access through the REAL security filter chain — the
 * evidence layer the unit tests cannot provide: a seed super admin changes
 * their forced password, switches into OWNER@tenant-1, and the act-claim token
 * must read the farm's live signals (map geometry + stream ticket) exactly
 * like the tenant owner, while the un-switched root token and a membership-less
 * B2B admin stay refused.
 */
@Testcontainers(disabledWithoutDocker = true)
class SignalAccessJourneyTest extends AbstractJourneyTest {

    private static final String FARM_1_MAP_URL =
            "/api/v1/farms/1/signals/map?cursor=0:0:0&includeGeometry=true";
    private static final String FARM_1_TICKET_URL = "/api/v1/farms/1/signals/stream-ticket";
    private static final String SUPER_ADMIN_ACCOUNT = "Admin@hkt.com";
    private static final String SEED_PASSWORD = "Admin@2026";
    private static final String CHANGED_PASSWORD = "Journey#Super1";

    @Test
    @DisplayName("switched super-admin context reads farm signals through the real filter chain")
    @SuppressWarnings("unchecked")
    void switchedSuperAdminContextReadsFarmSignals() {
        // Fresh-database seed super admin: forced password change gates the
        // context switch (switchContext re-checks the lock).
        String rootToken = login(SUPER_ADMIN_ACCOUNT, SEED_PASSWORD);
        assertOk(putRaw(rootToken, "/api/v1/me/password",
                Map.of("oldPassword", SEED_PASSWORD, "newPassword", CHANGED_PASSWORD)));

        ResponseEntity<Map> switchResp = postRaw(rootToken, "/api/v1/auth/switch-context",
                Map.of("role", "OWNER", "tenantId", 1));
        assertOk(switchResp);
        Map<String, Object> switchData = (Map<String, Object>) switchResp.getBody().get("data");
        String actToken = (String) switchData.get("accessToken");
        assertThat(actToken).isNotBlank();
        Map<String, Object> effectiveUser = (Map<String, Object>) switchData.get("user");
        assertThat(effectiveUser.get("role")).isEqualTo("OWNER");
        assertThat(effectiveUser.get("tenantId")).isEqualTo(1);

        // Member baseline through the real chain: the tenant owner reads signals.
        assertOk(getRaw(ownerToken, FARM_1_MAP_URL));

        // Switched context: same 200, fence geometry delivered, count matches
        // /fences (same table, no filter drift between the two read paths).
        assertOk(getRaw(actToken, FARM_1_MAP_URL));
        Map<String, Object> mapData =
                (Map<String, Object>) getRaw(actToken, FARM_1_MAP_URL).getBody().get("data");
        assertThat(mapData.get("farmId")).isEqualTo(1);
        assertThat((List<Object>) mapData.get("fences"))
                .hasSize(((List<Object>) getApi(ownerToken, "/api/v1/farms/1/fences").get("items")).size());

        // Stream ticket: the switched context gets one, like a member.
        assertOk(postRaw(actToken, FARM_1_TICKET_URL, Map.of()));

        // The un-switched root token stays refused on the same endpoint.
        assertError(getRaw(rootToken, FARM_1_MAP_URL), HttpStatus.FORBIDDEN, "AUTH_FORBIDDEN");
    }

    @Test
    @DisplayName("b2b admin without farm membership is refused farm signals")
    void b2bAdminWithoutMembershipIsRefused() {
        // NOT farm 1: FarmRanchJourneyTest's member-management flow adds the
        // b2b admin (userId 3) to farm 1 and its removal test is @Disabled,
        // so farm-1 memberships are polluted in a full-suite run. A fresh
        // farm auto-assigns only its creator (the owner) — provably
        // membership-less for the b2b admin. POST /farms answers 201 CREATED.
        ResponseEntity<Map> createdResp = postRaw(ownerToken, "/api/v1/farms", Map.of(
                "name", "SignalAccess-" + System.nanoTime(),
                "latitude", 28.20,
                "longitude", 112.90,
                "areaHectares", 100));
        assertThat(createdResp.getStatusCode()).isIn(HttpStatus.OK, HttpStatus.CREATED);
        Map<String, Object> created =
                (Map<String, Object>) createdResp.getBody().get("data");
        String farmId = String.valueOf(created.get("id"));

        assertError(getRaw(b2bAdminToken,
                        "/api/v1/farms/" + farmId
                                + "/signals/map?cursor=0:0:0&includeGeometry=true"),
                HttpStatus.FORBIDDEN, "AUTH_FORBIDDEN");
    }
}
