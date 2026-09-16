package com.smartlivestock.integration;

import com.smartlivestock.iot.application.TbDeviceProvisioningService;
import com.smartlivestock.iot.infrastructure.client.ns.NsClient;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbClient;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Journey tests for the TB device profile allowlist CRUD (NIX-214).
 * Runs against real Hibernate + PostgreSQL (Testcontainers, container declared
 * in AbstractJourneyTest) to cover the unique constraint, the audit trail,
 * role gating, and the preflight lifecycle coupling
 * (enable/disable/delete -> PENDING_TB_DEVICE).
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class DeviceProfileRuleJourneyTest extends AbstractJourneyTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private TbDeviceProvisioningService provisioningService;

    @MockBean
    private NsClient nsClient;

    @MockBean
    private TbClient tbClient;

    private static final String BASE = "/api/v1/admin/device-profile-rules";

    @AfterEach
    void clearTenant() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("种子迁移：两条现行白名单存在且启用（行为不变迁移）")
    void seedRulesShouldExistAndBeEnabled() {
        List<Map<String, Object>> items = listRules(platformAdminToken);
        assertThat(items).extracting(it -> it.get("profileName"))
                .contains("瘤胃胶囊-OC-配置-v2", "牛羊追踪器-OC-配置-v2");
        assertThat(items).allSatisfy(it ->
                assertThat(it.get("enabled")).isEqualTo(true));
        assertThat(items).extracting(it -> it.get("deviceType"))
                .contains("CAPSULE", "TRACKER");
    }

    @Test
    @DisplayName("CRUD：创建/重名 409/停用/更新忽略改名/删除/删除不存在 404")
    void crudShouldWork() {
        // create
        Map<String, Object> created = postApi(platformAdminToken, BASE, Map.of(
                "profileName", "测试追踪器-profile-A",
                "deviceType", "TRACKER",
                "enabled", true,
                "remark", "journey-test"));
        String id = extractId(created);
        assertThat(created.get("profileName")).isEqualTo("测试追踪器-profile-A");
        assertThat(created.get("deviceType")).isEqualTo("TRACKER");

        // duplicate name → 409
        ResponseEntity<Map> dup = postRaw(platformAdminToken, BASE, Map.of(
                "profileName", "测试追踪器-profile-A", "deviceType", "TRACKER"));
        assertError(dup, HttpStatus.CONFLICT, "DUPLICATE_RESOURCE");

        // update: disable + retype; profileName is immutable (ignored)
        Map<String, Object> updated = putApi(platformAdminToken, BASE + "/" + id, Map.of(
                "profileName", "试图改名-应被忽略",
                "deviceType", "CAPSULE",
                "enabled", false,
                "remark", "disabled"));
        assertThat(updated.get("profileName")).isEqualTo("测试追踪器-profile-A");
        assertThat(updated.get("deviceType")).isEqualTo("CAPSULE");
        assertThat(updated.get("enabled")).isEqualTo(false);

        // delete
        assertOk(deleteRaw(platformAdminToken, BASE + "/" + id));
        assertThat(listRules(platformAdminToken))
                .noneMatch(it -> id.equals(extractId(it)));

        // delete again → 404; update missing id → 404
        assertError(deleteRaw(platformAdminToken, BASE + "/" + id),
                HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
        assertError(putRaw(platformAdminToken, BASE + "/999999", Map.of(
                        "deviceType", "TRACKER", "enabled", true)),
                HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
    }

    @Test
    @DisplayName("权限：OWNER/WORKER 403，B2B_ADMIN 可读写")
    void roleGateShouldBlockNonPlatformAdmins() {
        assertError(getRaw(ownerToken, BASE), HttpStatus.FORBIDDEN, "AUTH_FORBIDDEN");
        assertError(postRaw(workerToken, BASE, Map.of(
                        "profileName", "x", "deviceType", "TRACKER")),
                HttpStatus.FORBIDDEN, "AUTH_FORBIDDEN");

        Map<String, Object> created = postApi(b2bAdminToken, BASE, Map.of(
                "profileName", "B2B可管理-profile", "deviceType", "TRACKER"));
        assertThat(created.get("id")).isNotNull();
        assertOk(deleteRaw(b2bAdminToken, BASE + "/" + extractId(created)));
    }

    @Test
    @DisplayName("审计：写操作落 audit_logs")
    void auditTrailShouldBeRecorded() {
        Integer before = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM audit_logs WHERE event_type LIKE 'DEVICE_PROFILE_RULE_%'",
                Integer.class);
        Map<String, Object> created = postApi(platformAdminToken, BASE, Map.of(
                "profileName", "审计-profile", "deviceType", "TRACKER"));
        assertOk(deleteRaw(platformAdminToken, BASE + "/" + extractId(created)));
        Integer after = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM audit_logs WHERE event_type LIKE 'DEVICE_PROFILE_RULE_%'",
                Integer.class);
        assertThat(after).isEqualTo(before + 2);
    }

    @Test
    @DisplayName("preflight 联动：停用/删除规则 → PENDING_TB_DEVICE，恢复 → READY_TO_INGEST")
    void preflightShouldRespectRuleLifecycle() {
        String eui = "e2e0000000000214";
        String profileName = "e2e-追踪器-profile";
        Map<String, Object> created = postApi(platformAdminToken, BASE, Map.of(
                "profileName", profileName, "deviceType", "TRACKER"));
        String id = extractId(created);

        when(nsClient.findDeviceByEui(eui)).thenReturn(Optional.of(
                new NsClient.NsDevice(eui, 89, 18, "journey-tracker")));
        when(tbClient.fetchDeviceProfiles())
                .thenReturn(Map.of("profile-1", profileName));
        when(tbClient.findDevices(eui)).thenReturn(List.of(
                new TbClient.TbDeviceView("tb-1", eui, "profile-1")));
        when(tbClient.fetchLatestTelemetryTs("tb-1")).thenReturn(Instant.now());

        TenantContext.setCurrentTenant(1L);
        assertThat(preflightStatus(eui)).isEqualTo("READY_TO_INGEST");

        // disable → no longer allowlisted
        putApi(platformAdminToken, BASE + "/" + id, Map.of(
                "deviceType", "TRACKER", "enabled", false));
        assertThat(preflightStatus(eui)).isEqualTo("PENDING_TB_DEVICE");

        // re-enable → allowlisted again
        putApi(platformAdminToken, BASE + "/" + id, Map.of(
                "deviceType", "TRACKER", "enabled", true));
        assertThat(preflightStatus(eui)).isEqualTo("READY_TO_INGEST");

        // delete → back to PENDING_TB_DEVICE
        assertOk(deleteRaw(platformAdminToken, BASE + "/" + id));
        assertThat(preflightStatus(eui)).isEqualTo("PENDING_TB_DEVICE");
    }

    private String preflightStatus(String eui) {
        return provisioningService.preflight(eui, 1L).status();
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> listRules(String token) {
        ResponseEntity<Map> resp = getRaw(token, BASE);
        assertOk(resp);
        return objectMapper.convertValue(resp.getBody().get("data"), List.class);
    }
}
