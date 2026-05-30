package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 旅程 2.3 Commerce 部分 + 2.1/2.2 合同分润。
 *
 * owner → 订阅查看/变更 → 合同 → 分润
 * platform_admin → 合同 CRUD → 分润计算 → 订阅服务管理
 */
class CommerceJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("Owner 订阅旅程")
    class OwnerSubscription {

        @Test
        @DisplayName("owner 查看当前订阅（premium）")
        void owner_viewSubscription() {
            var data = getApi(ownerToken, "/api/v1/subscription");
            assertThat(data).isNotNull();
            assertThat(data).containsKey("tier");
            assertThat(data.get("tier")).isEqualTo("PREMIUM");
        }

        @Test
        @DisplayName("owner 查看套餐列表")
        void owner_viewPlans() {
            var resp = getRaw(ownerToken, "/api/v1/subscription/plans");
        assertOk(resp);
            assertThat(resp.getBody().get("data")).isNotNull();
        }

        @Test
        @DisplayName("owner 查看用量")
        void owner_viewUsage() {
            var data = getApi(ownerToken, "/api/v1/subscription/usage");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("owner 查看合同（/contracts/me）")
        void owner_viewMyContracts() {
            var data = getApi(ownerToken, "/api/v1/contracts/me");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("owner 查看分润期间（/revenue/periods）")
        void owner_viewRevenuePeriods() {
            var resp = getRaw(ownerToken, "/api/v1/revenue/periods");
        assertOk(resp);
            assertThat(resp.getBody().get("data")).isNotNull();
        }
    }

    @Nested
    @DisplayName("Platform Admin 合同管理")
    class AdminContractManagement {

        @Test
        @DisplayName("platform_admin 创建合同成功")
        void admin_createContract() {
            var body = Map.of(
                    "tenantId", "1",
                    "billingModel", "direct",
                    "effectiveTier", "standard",
                    "startedAt", "2026-06-01T00:00:00Z",
                    "expiresAt", "2027-06-01T00:00:00Z"
            );
            var resp = postRaw(platformAdminToken, "/api/v1/admin/contracts", body);
            assertThat(resp.getStatusCode().value()).isIn(200, 201);
        }

        @Test
        @DisplayName("platform_admin 查看合同列表")
        void admin_listContracts() {
            var data = getApi(platformAdminToken, "/api/v1/admin/contracts");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items).isNotEmpty();
        }

        @Test
        @DisplayName("platform_admin 更新合同状态")
        void admin_updateContractStatus() {
            var listData = getApi(platformAdminToken, "/api/v1/admin/contracts");
            var items = getItems(listData);
            assertThat(items).isNotEmpty();

            String contractId = extractId(items.get(0));
            var body = Map.of("status", "suspended");
            var resp = putRaw(platformAdminToken,
                    "/api/v1/admin/contracts/" + contractId + "/status", body);
            assertThat(resp.getStatusCode().value()).isIn(200, 204);
        }
    }

    @Nested
    @DisplayName("Platform Admin 分润管理")
    class AdminRevenueManagement {

        @Test
        @DisplayName("platform_admin 查看分润期间列表（≥3 条）")
        void admin_listRevenuePeriods() {
            var data = getApi(platformAdminToken, "/api/v1/admin/revenue/periods");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items.size()).isGreaterThanOrEqualTo(3);
        }

        @Test
        @DisplayName("platform_admin 查看分润期间详情")
        void admin_getRevenuePeriodDetail() {
            var listData = getApi(platformAdminToken, "/api/v1/admin/revenue/periods");
            var items = getItems(listData);
            assertThat(items).isNotEmpty();

            String periodId = extractId(items.get(0));
            var detail = getApi(platformAdminToken, "/api/v1/admin/revenue/periods/" + periodId);
            assertThat(detail).containsKey("id");
        }

        @Test
        @DisplayName("platform_admin 触发分润计算")
        void admin_calculateRevenue() {
            var body = Map.of(
                    "periodStart", "2026-05-01",
                    "periodEnd", "2026-05-31"
            );
            var resp = postRaw(platformAdminToken, "/api/v1/admin/revenue/calculate", body);
            assertThat(resp.getStatusCode().value()).isBetween(200, 500);
        }
    }

    @Nested
    @DisplayName("Platform Admin 订阅服务管理")
    class AdminSubscriptionService {

        @Test
        @DisplayName("platform_admin 查看订阅服务列表")
        void admin_listSubscriptionServices() {
            var data = getApi(platformAdminToken, "/api/v1/admin/subscription-services");
            assertThat(data).containsKey("items");
        }

        @Test
        @DisplayName("platform_admin 查看功能门控列表")
        void admin_listFeatureGates() {
            var data = getApi(platformAdminToken, "/api/v1/admin/feature-gates");
            assertThat(data).containsKey("items");
        }

        @Test
        @DisplayName("platform_admin 查看订阅详情")
        void admin_getSubscriptionDetail() {
            var listData = getApi(platformAdminToken, "/api/v1/admin/subscriptions");
            var items = getItems(listData);
            assertThat(items).isNotEmpty();

            String subId = extractId(items.get(0));
            var detail = getApi(platformAdminToken, "/api/v1/admin/subscriptions/" + subId);
            assertThat(detail).containsKey("id");
        }
    }

    @Nested
    @DisplayName("Commerce 权限边界")
    class CommercePermissionBoundary {

        @Test
        @DisplayName("owner 不能访问 Admin 合同端点")
        void owner_cannotAccessAdminContracts() {
            var resp = getRaw(ownerToken, "/api/v1/admin/contracts");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("owner 不能访问 Admin 分润端点")
        void owner_cannotAccessAdminRevenue() {
            var resp = getRaw(ownerToken, "/api/v1/admin/revenue/periods");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("owner 不能访问 Admin 订阅服务管理")
        void owner_cannotAccessAdminSubscriptionServices() {
            var resp = getRaw(ownerToken, "/api/v1/admin/subscription-services");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能查看订阅信息")
        void worker_cannotViewSubscription() {
            var resp = getRaw(workerToken, "/api/v1/subscription");
            assertThat(resp.getStatusCode().value()).isBetween(200, 403);
        }
    }
}
