package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Legacy journey test — now extends AbstractJourneyTest for shared infrastructure.
 * Original test preserved for backward compatibility.
 */
class JourneyIntegrationTest extends AbstractJourneyTest {

    @Test
    @DisplayName("完整客户旅程 — 4 角色登录 + 数据验证 + 权限边界")
    void fullCustomerJourney() {
        // --- Step 1: platform_admin 登录验证 ---
        assertThat(platformAdminToken).isNotNull();

        // --- Step 2: owner 查看 2 个牧场 ---
        Map<String, Object> farmsData = getApi(ownerToken, "/api/v1/farms");
        List<Map<String, Object>> farms = (List<Map<String, Object>>) farmsData.get("items");
        assertThat(farms).hasSizeGreaterThanOrEqualTo(2);

        // --- Step 3: owner 查看 Farm 1 数据 (50 livestock, 4 fences, 18 alerts) ---
        Map<String, Object> farm1Livestock = getApi(ownerToken, "/api/v1/farms/1/livestock?page=0&size=1");
        assertThat(farm1Livestock.get("total")).isEqualTo(50);

        Map<String, Object> farm1Fences = getApi(ownerToken, "/api/v1/farms/1/fences?page=0&size=1");
        assertThat(farm1Fences.get("total")).isEqualTo(4);

        Map<String, Object> farm1Alerts = getApi(ownerToken, "/api/v1/farms/1/alerts?page=0&size=1");
        assertThat(farm1Alerts.get("total")).isEqualTo(18);

        // --- Step 4: owner 切换到 Farm 2 (10 livestock, 2 fences, 5 alerts) ---
        Map<String, Object> farm2Livestock = getApi(ownerToken, "/api/v1/farms/2/livestock?page=0&size=1");
        assertThat(farm2Livestock.get("total")).isEqualTo(10);

        Map<String, Object> farm2Fences = getApi(ownerToken, "/api/v1/farms/2/fences?page=0&size=1");
        assertThat(farm2Fences.get("total")).isEqualTo(2);

        Map<String, Object> farm2Alerts = getApi(ownerToken, "/api/v1/farms/2/alerts?page=0&size=1");
        assertThat(farm2Alerts.get("total")).isEqualTo(5);

        // --- Step 5: b2b_admin 查看牧场列表 ---
        Map<String, Object> b2bFarms = getApi(b2bAdminToken, "/api/v1/farms");
        assertThat((Integer) b2bFarms.get("total")).isGreaterThanOrEqualTo(2);

        // --- Step 6: worker 确认一条 PENDING 告警 ---
        Map<String, Object> workerAlerts = getApi(workerToken, "/api/v1/farms/1/alerts?page=0&size=20");
        List<Map<String, Object>> workerAlertItems = (List<Map<String, Object>>) workerAlerts.get("items");
        Map<String, Object> pendingAlert = workerAlertItems.stream()
                .filter(a -> "PENDING".equals(a.get("status")))
                .findFirst()
                .orElseThrow(() -> new AssertionError("No PENDING alert found"));
        Long alertId = ((Number) pendingAlert.get("id")).longValue();

        Map<String, Object> ackResult = postApi(workerToken, "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);
        assertThat(ackResult).isNotNull();

        // --- Step 7: worker 尝试处理告警（无权限应被拒绝） ---
        var handleResp = postRaw(workerToken, "/api/v1/farms/1/alerts/" + alertId + "/handle", null);
        assertThat(handleResp.getBody().get("code")).isNotEqualTo("OK");
    }
}
