package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 个人信息 + 看板 + 地图 + 多牧场切换 旅程。
 *
 * GET /me → PUT /me → GET /tenants/me → Dashboard → Map → 牧场切换数据隔离
 */
class DashboardMeJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("个人资料旅程")
    class MeProfile {

        @Test
        @DisplayName("GET /me 返回当前用户信息")
        void getMe_returnsUserInfo() {
            var data = getApi(ownerToken, "/api/v1/me");
            assertThat(data).containsKey("id");
            assertThat(data).containsKey("phone");
            assertThat(data).containsKey("role");
            assertThat(data.get("phone")).isEqualTo("13800138000");
            assertThat(data).containsKey("tenantId");
        }

        @Test
        @DisplayName("PUT /me 更新用户信息")
        void putMe_updatesProfile() {
            var body = Map.of("name", "牧场主更新名");
            var resp = putRaw(ownerToken, "/api/v1/me", body);
            assertThat(resp.getStatusCode().value()).isIn(200, 204);

            var data = getApi(ownerToken, "/api/v1/me");
            assertThat(data.get("name")).isEqualTo("牧场主更新名");
        }

        @Test
        @DisplayName("GET /tenants/me 返回当前租户信息")
        void getTenantsMe_returnsTenantInfo() {
            var data = getApi(ownerToken, "/api/v1/tenants/me");
            assertThat(data).containsKey("id");
            assertThat(data).containsKey("name");
            assertThat(data.get("name")).isEqualTo("Demo牧场");
        }

        @Test
        @DisplayName("platform_admin GET /tenants/me 无租户归属")
        void platformAdmin_tenantsMe_noTenant() {
            var resp = getRaw(platformAdminToken, "/api/v1/tenants/me");
            assertThat(resp.getStatusCode().value()).isIn(200, 404);
        }
    }

    @Nested
    @DisplayName("Dashboard 旅程")
    class DashboardJourney {

        @Test
        @DisplayName("owner 查看 Farm 1 Dashboard 汇总")
        void owner_dashboardSummary_farm1() {
            var data = getApi(ownerToken, "/api/v1/farms/1/dashboard/summary");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("owner 查看 Farm 2 Dashboard 汇总")
        void owner_dashboardSummary_farm2() {
            var data = getApi(ownerToken, "/api/v1/farms/2/dashboard/summary");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("Dashboard 数据与牧场关联正确")
        void dashboardData_matchesFarm() {
            var farm1Data = getApi(ownerToken, "/api/v1/farms/1/dashboard/summary");
            var farm2Data = getApi(ownerToken, "/api/v1/farms/2/dashboard/summary");
            assertThat(farm1Data).isNotEqualTo(farm2Data);
        }
    }

    @Nested
    @DisplayName("地图旅程")
    class MapJourney {

        @Test
        @DisplayName("owner 查看 Farm 1 地图概览")
        void owner_mapOverview_farm1() {
            var data = getApi(ownerToken, "/api/v1/farms/1/map/overview");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("owner 查看 Farm 2 地图概览")
        void owner_mapOverview_farm2() {
            var data = getApi(ownerToken, "/api/v1/farms/2/map/overview");
            assertThat(data).isNotNull();
        }
    }

    @Nested
    @DisplayName("多牧场切换数据隔离")
    class MultiFarmIsolation {

        @Test
        @DisplayName("Farm 1 牲畜 50 头，Farm 2 牲畜 10 头")
        void livestockCount_diffBetweenFarms() {
            var farm1 = getApi(ownerToken, "/api/v1/farms/1/livestock?page=0&size=1");
            var farm2 = getApi(ownerToken, "/api/v1/farms/2/livestock?page=0&size=1");

            assertThat(((Number) farm1.get("total")).longValue()).isEqualTo(50);
            assertThat(((Number) farm2.get("total")).longValue()).isEqualTo(10);
        }

        @Test
        @DisplayName("Farm 1 围栏 ≥4 个，Farm 2 围栏 =2 个")
        void fenceCount_diffBetweenFarms() {
            var farm1 = getApi(ownerToken, "/api/v1/farms/1/fences");
            var farm2 = getApi(ownerToken, "/api/v1/farms/2/fences");

            assertThat(getItems(farm1).size()).isGreaterThanOrEqualTo(4);
            assertThat(getItems(farm2).size()).isEqualTo(2);
        }

        @Test
        @DisplayName("Farm 1 告警 ≥18 条，Farm 2 告警 =5 条")
        void alertCount_diffBetweenFarms() {
            var farm1 = getApi(ownerToken, "/api/v1/farms/1/alerts?page=0&size=1");
            var farm2 = getApi(ownerToken, "/api/v1/farms/2/alerts?page=0&size=1");

            assertThat(((Number) farm1.get("total")).longValue()).isGreaterThanOrEqualTo(18);
            assertThat(((Number) farm2.get("total")).longValue()).isEqualTo(5);
        }

        @Test
        @DisplayName("不存在的农场返回 404/403")
        void nonexistentFarm_returnsError() {
            var resp = getRaw(ownerToken, "/api/v1/farms/99999/livestock");
            assertThat(resp.getStatusCode().value()).isIn(403, 404);
        }
    }
}
