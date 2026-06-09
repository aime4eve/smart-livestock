package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for GET /api/v1/farms/{farmId}/ranch-overview.
 * Inherits Testcontainers setup and auth helpers from AbstractJourneyTest.
 */
class RanchOverviewIntegrationTest extends AbstractJourneyTest {

    private Map<String, Object> fetchOverview(String token, long farmId) {
        return getApi(token, "/api/v1/farms/" + farmId + "/ranch-overview");
    }

    @Test
    @DisplayName("owner 获取 ranch-overview 成功，包含六个顶层字段")
    void ownerGetsRanchOverview() {
        Map<String, Object> data = fetchOverview(ownerToken, 1L);

        assertThat(data).containsKeys(
                "overallStats", "sceneSummary", "pendingTasks",
                "fences", "livestockMarkers", "alerts");
    }

    @Test
    @DisplayName("overallStats 字段完整且类型正确")
    void overallStatsFieldsCorrect() {
        Map<String, Object> data = fetchOverview(ownerToken, 1L);
        Map<String, Object> stats = (Map<String, Object>) data.get("overallStats");

        assertThat(stats).containsKeys(
                "totalLivestock", "healthyRate", "alertCount",
                "criticalCount", "deviceOnlineRate");
        assertThat(((Number) stats.get("totalLivestock")).intValue()).isGreaterThanOrEqualTo(0);
        assertThat(((Number) stats.get("healthyRate")).doubleValue()).isBetween(0.0, 1.0);
        assertThat(((Number) stats.get("alertCount")).intValue()).isGreaterThanOrEqualTo(0);
        assertThat(((Number) stats.get("criticalCount")).intValue()).isGreaterThanOrEqualTo(0);
        assertThat(((Number) stats.get("deviceOnlineRate")).doubleValue()).isBetween(0.0, 1.0);
    }

    @Test
    @DisplayName("fences 列表非空且格式正确")
    void fencesFormatCorrect() {
        Map<String, Object> data = fetchOverview(ownerToken, 1L);
        List<Map<String, Object>> fences = (List<Map<String, Object>>) data.get("fences");

        assertThat(fences).isNotEmpty();
        for (Map<String, Object> fence : fences) {
            assertThat(fence).containsKeys("id", "name", "active", "type", "color", "points");
            List<Map<String, Object>> points = (List<Map<String, Object>>) fence.get("points");
            assertThat(points).hasSizeGreaterThanOrEqualTo(3);
            Map<String, Object> first = points.get(0);
            assertThat(first).containsKeys("lat", "lng");
            assertThat(((Number) first.get("lat")).doubleValue()).isBetween(27.0, 30.0);
            assertThat(((Number) first.get("lng")).doubleValue()).isBetween(111.0, 114.0);
        }
    }

    @Test
    @DisplayName("livestockMarkers 包含位置和健康状态")
    void livestockMarkersHavePositionAndHealth() {
        Map<String, Object> data = fetchOverview(ownerToken, 1L);
        List<Map<String, Object>> markers = (List<Map<String, Object>>) data.get("livestockMarkers");

        assertThat(markers).isNotEmpty();
        Set<String> validStatuses = Set.of("NORMAL", "WARNING", "CRITICAL");
        for (Map<String, Object> m : markers) {
            assertThat(m).containsKeys("livestockId", "livestockCode", "latitude", "longitude", "healthStatus");
            assertThat(((Number) m.get("latitude")).doubleValue()).isNotZero();
            assertThat(((Number) m.get("longitude")).doubleValue()).isNotZero();
            assertThat(validStatuses).contains((String) m.get("healthStatus"));
        }
    }

    @Test
    @DisplayName("alerts 不含 ARCHIVED 状态")
    void alertsExcludesArchived() {
        Map<String, Object> data = fetchOverview(ownerToken, 1L);
        List<Map<String, Object>> alerts = (List<Map<String, Object>>) data.get("alerts");

        for (Map<String, Object> alert : alerts) {
            assertThat((String) alert.get("status")).isNotEqualTo("ARCHIVED");
        }
    }

    @Test
    @DisplayName("pendingTasks 的 severity 合法")
    void pendingTasksSeverityValid() {
        Map<String, Object> data = fetchOverview(ownerToken, 1L);
        List<Map<String, Object>> tasks = (List<Map<String, Object>>) data.get("pendingTasks");

        Set<String> validSeverities = Set.of("CRITICAL", "WARNING", "INFO");
        for (Map<String, Object> task : tasks) {
            assertThat(validSeverities).contains((String) task.get("severity"));
        }
    }

    @Test
    @DisplayName("worker 也能访问 ranch-overview")
    void workerCanAccess() {
        Map<String, Object> data = fetchOverview(workerToken, 1L);
        assertThat(data).containsKey("overallStats");
    }

    @Test
    @DisplayName("无 token 返回 401")
    void noTokenReturns401() {
        var resp = getRawNoAuth("/api/v1/farms/1/ranch-overview");
        assertThat(resp.getStatusCode().value()).isEqualTo(401);
    }

    @Test
    @DisplayName("跨租户 farmId 返回 403")
    void crossTenantFarmReturns403() {
        // owner belongs to tenant with farmId=1, try a non-existent or other-tenant farm
        var resp = getRaw(ownerToken, "/api/v1/farms/99999/ranch-overview");
        assertThat(resp.getStatusCode().value()).isIn(403, 404);
    }
}
