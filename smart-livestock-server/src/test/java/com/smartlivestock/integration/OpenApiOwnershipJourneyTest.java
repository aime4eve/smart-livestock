package com.smartlivestock.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * NIX-333 — Open API resource-in-farm checks.
 *
 * Seeds give tenant 1 two farms (主牧场 id 1 with installations + GPS logs,
 * 南山分场 id 2 with its own livestock/fences/alerts). An API key for tenant 1
 * passes {@code validateFarmAccess} on both farms, so every cross-farm read
 * below used to succeed; they must now answer 404 (or 403 for the
 * tenant-scoped device) while same-farm reads keep returning 200.
 *
 * {@code /api/v1/open/**} sits behind the Redis-backed RateLimitInterceptor,
 * which the shared journey context has no Redis for (every open call 500s) —
 * the reason the Open API had no journey coverage at all. This class brings
 * its own Redis container, so it runs in its own Spring context.
 */
@DisplayName("Open API 归属校验：跨牧场 404 / 跨租户 403 / 本牧场 200")
class OpenApiOwnershipJourneyTest extends AbstractJourneyTest {

    @Container
    static GenericContainer<?> redis = new GenericContainer<>("redis:7-alpine")
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void redisProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", () -> redis.getMappedPort(6379));
        registry.add("spring.data.redis.password", () -> "");
    }

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private String apiKey;

    /**
     * KNOWN DEFECT (not fixed here — shared/security needs a user ruling):
     * ApiKeyAuthFilter puts the API key's id into the SecurityContext as a
     * Long principal, and PasswordChangeRequiredInterceptor reads any Long
     * principal as a user id — so a key whose id equals a user with
     * must_change_password=TRUE gets 403 PASSWORD_CHANGE_REQUIRED on every
     * open call. Minting keys above MAX(users.id) makes the collision
     * impossible without mutating the shared test database.
     */
    @BeforeEach
    void seedApiKey() {
        if (apiKey != null) {
            return;
        }
        long maxUserId = jdbcTemplate.queryForObject(
                "SELECT COALESCE(MAX(id), 0) FROM users", Long.class);
        for (int attempt = 0; attempt < 20; attempt++) {
            var resp = postRaw(platformAdminToken, "/api/v1/admin/api-keys", Map.of(
                    "name", "nix333-" + System.nanoTime(),
                    "role", "api_consumer",
                    "tenantId", 1,
                    "scopes", List.of("livestock:read", "fence:read", "alert:read",
                            "device:read", "gps:read")));
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) resp.getBody().get("data");
            String rawKey = (String) data.get("rawKey");
            assertThat(rawKey).startsWith("sk_");
            if (((Number) data.get("id")).longValue() > maxUserId) {
                apiKey = rawKey;
                return;
            }
        }
        throw new IllegalStateException(
                "no api key above the user-id range after 20 attempts");
    }

    // ── helpers ─────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private ResponseEntity<Map> openGet(String path) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-API-Key", apiKey);
        return restTemplate.exchange(path, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
    }

    @SuppressWarnings("unchecked")
    private long firstIdOf(String listPath) {
        var resp = openGet(listPath);
        assertOk(resp);
        List<Map<String, Object>> items = getItems((Map<String, Object>) resp.getBody().get("data"));
        assertThat(items).as("seed data for " + listPath).isNotEmpty();
        return ((Number) items.get(0).get("id")).longValue();
    }

    private void assertNotFound(ResponseEntity<Map> resp) {
        assertError(resp, HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
    }

    // ── livestock detail ────────────────────────────────────────────

    @Test
    @DisplayName("livestock/{id}：本牧场 200，跨牧场 404（两方向）")
    void livestockDetail_crossFarmIs404() {
        long farm1Livestock = firstIdOf("/api/v1/open/farms/1/livestock");
        long farm2Livestock = firstIdOf("/api/v1/open/farms/2/livestock");

        assertOk(openGet("/api/v1/open/farms/1/livestock/" + farm1Livestock));
        assertOk(openGet("/api/v1/open/farms/2/livestock/" + farm2Livestock));
        assertNotFound(openGet("/api/v1/open/farms/2/livestock/" + farm1Livestock));
        assertNotFound(openGet("/api/v1/open/farms/1/livestock/" + farm2Livestock));
        assertNotFound(openGet("/api/v1/open/farms/1/livestock/999999"));
    }

    // ── livestock gps history ───────────────────────────────────────

    @Test
    @DisplayName("livestock/{id}/gps-logs：本牧场 200，跨牧场 404")
    void gpsHistory_crossFarmIs404() {
        long farm1Livestock = firstIdOf("/api/v1/open/farms/1/livestock");

        assertOk(openGet("/api/v1/open/farms/1/livestock/" + farm1Livestock + "/gps-logs"));
        assertNotFound(openGet("/api/v1/open/farms/2/livestock/" + farm1Livestock + "/gps-logs"));
    }

    // ── latest gps (farm-wide) ──────────────────────────────────────

    @Test
    @SuppressWarnings("unchecked")
    @DisplayName("gps-logs/latest：只返回本牧场牲畜的位置，不再泄漏其它牧场/租户")
    void latestGps_isScopedToFarm() {
        var farm1 = openGet("/api/v1/open/farms/1/gps-logs/latest");
        var farm2 = openGet("/api/v1/open/farms/2/gps-logs/latest");
        assertOk(farm1);
        assertOk(farm2);

        List<Map<String, Object>> farm1Items =
                getItems((Map<String, Object>) farm1.getBody().get("data"));
        List<Map<String, Object>> farm2Items =
                getItems((Map<String, Object>) farm2.getBody().get("data"));

        // Seeds install trackers on farm 1 livestock only.
        assertThat(farm1Items).as("farm 1 has seeded installations").isNotEmpty();
        Set<Object> farm1Devices = farm1Items.stream()
                .map(i -> i.get("deviceId")).collect(Collectors.toSet());
        Set<Object> farm2Devices = farm2Items.stream()
                .map(i -> i.get("deviceId")).collect(Collectors.toSet());
        // Pre-fix both calls returned the identical global set.
        assertThat(farm2Devices).doesNotContainAnyElementsOf(farm1Devices);
    }

    // ── fence detail ────────────────────────────────────────────────

    @Test
    @DisplayName("fences/{id}：本牧场 200，跨牧场 404")
    void fenceDetail_crossFarmIs404() {
        long farm1Fence = firstIdOf("/api/v1/open/farms/1/fences");
        long farm2Fence = firstIdOf("/api/v1/open/farms/2/fences");

        assertOk(openGet("/api/v1/open/farms/1/fences/" + farm1Fence));
        assertNotFound(openGet("/api/v1/open/farms/2/fences/" + farm1Fence));
        assertNotFound(openGet("/api/v1/open/farms/1/fences/" + farm2Fence));
    }

    // ── alert detail ────────────────────────────────────────────────

    @Test
    @DisplayName("alerts/{id}：本牧场 200，跨牧场 404")
    void alertDetail_crossFarmIs404() {
        long farm1Alert = firstIdOf("/api/v1/open/farms/1/alerts");
        long farm2Alert = firstIdOf("/api/v1/open/farms/2/alerts");

        assertOk(openGet("/api/v1/open/farms/1/alerts/" + farm1Alert));
        assertNotFound(openGet("/api/v1/open/farms/2/alerts/" + farm1Alert));
        assertNotFound(openGet("/api/v1/open/farms/1/alerts/" + farm2Alert));
    }

    // ── device detail (tenant-scoped) ───────────────────────────────

    @Test
    @SuppressWarnings("unchecked")
    @DisplayName("devices/{id}：本租户 200，他租户设备 403，不存在 404")
    void deviceDetail_crossTenantIs403() {
        long ownDevice = firstIdOf("/api/v1/open/farms/1/devices");
        assertOk(openGet("/api/v1/open/farms/1/devices/" + ownDevice));

        var tenantResp = postRaw(platformAdminToken, "/api/v1/admin/tenants", Map.of(
                "name", "NIX333-other-" + System.nanoTime(),
                "contactName", "other",
                "contactPhone", "+8613999" + String.format("%04d", System.nanoTime() % 10000)));
        assertThat(tenantResp.getStatusCode()).isIn(HttpStatus.OK, HttpStatus.CREATED);
        long otherTenantId = ((Number) ((Map<String, Object>) tenantResp.getBody().get("data"))
                .get("id")).longValue();

        Long otherDeviceId = jdbcTemplate.queryForObject(
                "INSERT INTO devices (tenant_id, device_code, device_type, status) "
                        + "VALUES (?, ?, 'TRACKER', 'ACTIVE') RETURNING id",
                Long.class, otherTenantId, "NIX333-" + System.nanoTime());

        assertError(openGet("/api/v1/open/farms/1/devices/" + otherDeviceId),
                HttpStatus.FORBIDDEN, "AUTH_FORBIDDEN");
        assertNotFound(openGet("/api/v1/open/farms/1/devices/999999"));
    }

    // ── farm gate precedes the resource gate ────────────────────────

    @Test
    @DisplayName("不存在的牧场路径：牧场门先行 404，不触及资源校验")
    void unknownFarm_is404() {
        var resp = openGet("/api/v1/open/farms/999999/livestock/1");
        assertThat(resp.getStatusCode()).as("body=%s", resp.getBody())
                .isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(resp.getBody().get("code")).isEqualTo("RESOURCE_NOT_FOUND");
    }
}
