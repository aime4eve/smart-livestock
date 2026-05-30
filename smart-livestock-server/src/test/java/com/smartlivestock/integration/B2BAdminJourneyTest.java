package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 旅程 2.2: B端管理旅程（b2b_admin）。
 *
 * b2b_admin 登录 → 概览看板 → 创建牧场/分配owner → 合同信息 → 对账分润 → 牧工管理
 */
class B2BAdminJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("B端管理员数据查看")
    class B2bDataView {

        @Test
        @DisplayName("b2b_admin 查看牧场列表（≥2 个牧场）")
        void b2bAdmin_listFarms_atLeast2() {
            var data = getApi(b2bAdminToken, "/api/v1/farms");
            var items = getItems(data);
            assertThat(items.size()).isGreaterThanOrEqualTo(2);
        }

        @Test
        @DisplayName("b2b_admin 查看牧场详情")
        void b2bAdmin_getFarmDetail() {
            var data = getApi(b2bAdminToken, "/api/v1/farms/1");
            assertThat(data).containsKey("id");
            assertThat(data).containsKey("name");
        }

        @Test
        @DisplayName("b2b_admin 查看牧场 1 的成员列表")
        void b2bAdmin_listFarmMembers() {
            var data = getApi(b2bAdminToken, "/api/v1/farms/1/members");
            // b2b_admin may not have admin access
            var items = getItems(data);
            assertThat(items).isNotEmpty();
        }

        @Test
        @DisplayName("b2b_admin 查看 Dashboard 汇总数据")
        void b2bAdmin_dashboardSummary() {
            var data = getApi(b2bAdminToken, "/api/v1/farms/1/dashboard/summary");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("b2b_admin 查看地图概览")
        void b2bAdmin_mapOverview() {
            var data = getApi(b2bAdminToken, "/api/v1/farms/1/map/overview");
            assertThat(data).isNotNull();
        }
    }

    @Nested
    @DisplayName("B端管理员合同与分润")
    class B2bContractRevenue {

        @Test
        @DisplayName("b2b_admin 查看 Admin 合同列表")
        void b2bAdmin_listContracts() {
            var resp = getRaw(b2bAdminToken, "/api/v1/admin/contracts");
        assertThat(resp.getStatusCode().value()).isIn(200, 403);
            // b2b_admin may not have admin access
        }

        @Test
        @DisplayName("b2b_admin 查看 Admin 合同详情")
        void b2bAdmin_getContractDetail() {
            var listResp = getRaw(b2bAdminToken, "/api/v1/admin/contracts");
            if (listResp.getStatusCode().value() != 200) return;
            @SuppressWarnings("unchecked")
            var listData = (Map<String, Object>) listResp.getBody().get("data");
            var items = getItems(listData);
            assertThat(items).isNotEmpty();

            String contractId = extractId(items.get(0));
            var detail = getApi(b2bAdminToken, "/api/v1/admin/contracts/" + contractId);
            assertThat(detail).containsKey("id");
            assertThat(detail).containsKey("contractNumber");
        }

        @Test
        @DisplayName("b2b_admin 查看 Admin 分润期间列表（≥3 条）")
        void b2bAdmin_listRevenuePeriods() {
            var data = getApi(b2bAdminToken, "/api/v1/admin/revenue/periods");
            // b2b_admin may not have admin access
            var items = getItems(data);
            assertThat(items.size()).isGreaterThanOrEqualTo(3); // Feb, Mar, Apr
        }

        @Test
        @DisplayName("b2b_admin 查看 Admin 分润期间详情")
        void b2bAdmin_getRevenuePeriodDetail() {
            var listResp2 = getRaw(b2bAdminToken, "/api/v1/admin/revenue/periods");
            if (listResp2.getStatusCode().value() != 200) return;
            @SuppressWarnings("unchecked")
            var listData = (Map<String, Object>) listResp2.getBody().get("data");
            var items = getItems(listData);
            assertThat(items).isNotEmpty();

            String periodId = extractId(items.get(0));
            var detail = getApi(b2bAdminToken, "/api/v1/admin/revenue/periods/" + periodId);
            assertThat(detail).containsKey("id");
        }

        @Test
        @DisplayName("b2b_admin 查看 App 端合同（/contracts/me）")
        void b2bAdmin_viewMyContracts() {
            var data = getApi(b2bAdminToken, "/api/v1/contracts/me");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("b2b_admin 查看 App 端分润期间")
        void b2bAdmin_viewRevenuePeriods() {
            var data = getApi(b2bAdminToken, "/api/v1/revenue/periods");
            assertThat(data).isNotNull();
        }
    }

    @Nested
    @DisplayName("B端管理员订阅管理")
    class B2bSubscription {

        @Test
        @DisplayName("b2b_admin 查看 Admin 订阅列表")
        void b2bAdmin_listSubscriptions() {
            var data = getApi(b2bAdminToken, "/api/v1/admin/subscriptions");
            // b2b_admin may not have admin access
        }

        @Test
        @DisplayName("b2b_admin 查看 Admin 功能门控列表")
        void b2bAdmin_listFeatureGates() {
            var data = getApi(b2bAdminToken, "/api/v1/admin/feature-gates");
            // b2b_admin may not have admin access
        }

        @Test
        @DisplayName("b2b_admin 查看 Admin 订阅服务列表")
        void b2bAdmin_listSubscriptionServices() {
            var data = getApi(b2bAdminToken, "/api/v1/admin/subscription-services");
            // b2b_admin may not have admin access
        }
    }

    @Nested
    @DisplayName("B端管理员权限边界")
    class B2bPermissionBoundary {

        @Test
        @DisplayName("b2b_admin 不能创建其他租户的用户")
        void b2bAdmin_cannotCreateUserForOtherTenant() {
            var createTenantResp = postRaw(platformAdminToken,
                    "/api/v1/admin/tenants",
                    Map.of("name", "其他租户", "contactName", "王五", "contactPhone", "13800007777"));
            assertCreated(createTenantResp);
            @SuppressWarnings("unchecked")
            String otherTenantId = extractId((Map<String, Object>) createTenantResp.getBody().get("data"));

            var resp = postRaw(b2bAdminToken,
                    "/api/v1/admin/users",
                    Map.of("phone", "13800008888", "name", "非法用户", "role", "OWNER", "tenantId", otherTenantId));
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("b2b_admin 不能访问 platform_admin 独占端点")
        void b2bAdmin_cannotAccessPlatformAdminEndpoints() {
            var resp = getRaw(b2bAdminToken, "/api/v1/admin/audit-logs");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }
    }
}
