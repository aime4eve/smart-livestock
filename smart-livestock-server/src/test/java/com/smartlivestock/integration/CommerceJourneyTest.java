package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

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
            var resp = getRaw(ownerToken, "/api/v1/contracts/me");
            // Demo 租户有种子合同，预期 200
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        }

        @Test
        @DisplayName("owner 查看分润期间（/revenue/periods）")
        void owner_viewRevenuePeriods() {
            var resp = getRaw(ownerToken, "/api/v1/revenue/periods");
        assertOk(resp);
            assertThat(resp.getBody().get("data")).isNotNull();
        }

        @Test
        @DisplayName("owner checkout 升级订阅")
        void owner_checkoutUpgrade() {
            try {
                var body = Map.of(
                        "tier", "ENTERPRISE",
                        "billingCycle", "monthly"
                );
                var resp = postRaw(ownerToken, "/api/v1/subscription/checkout", body);
                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                assertThat(resp.getBody()).isNotNull();
            } finally {
                // 无论如何恢复为 premium
                postRaw(ownerToken, "/api/v1/subscription/checkout",
                        Map.of("tier", "PREMIUM", "billingCycle", "monthly"));
            }
        }

        @Test
        @DisplayName("owner PUT /subscription/tier 降级订阅")
        void owner_downgradeTier() {
            var current = getApi(ownerToken, "/api/v1/subscription");
            assertThat(current.get("tier")).isEqualTo("PREMIUM");

            var body = Map.of("tier", "STANDARD");
            try {
                var resp = putRaw(ownerToken, "/api/v1/subscription/tier", body);
                // 降级可能被业务规则拒绝（409 CONFLICT）
                assertThat(resp.getStatusCode().value()).isIn(200, 409);
            } finally {
                // 无论如何恢复为 premium
                putRaw(ownerToken, "/api/v1/subscription/tier", Map.of("tier", "PREMIUM"));
                postRaw(ownerToken, "/api/v1/subscription/checkout", Map.of("tier", "PREMIUM", "billingCycle", "monthly"));
            }
        }

        @Test
        @DisplayName("owner POST /subscription/cancel 取消订阅")
        void owner_cancelSubscription() {
            try {
                var resp = postRaw(ownerToken, "/api/v1/subscription/cancel", null);
                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
            } finally {
                // 无论如何恢复订阅
                postRaw(ownerToken, "/api/v1/subscription/checkout", Map.of("tier", "PREMIUM", "billingCycle", "monthly"));
            }
        }
    }

    @Nested
    @DisplayName("Platform Admin 合同管理")
    class AdminContractManagement {

        @Test
        @DisplayName("platform_admin 创建合同成功")
        void admin_createContract() {
            // Create a new tenant first to avoid unique constraint on existing tenant
            var createTenantResp = postRaw(platformAdminToken,
                    "/api/v1/admin/tenants",
                    Map.of("name", "合同测试租户", "contactName", "合同测试", "contactPhone", "13700999999"));
            assertThat(createTenantResp.getStatusCode().value()).isEqualTo(201);
            @SuppressWarnings("unchecked")
            String tenantId = extractId((Map<String, Object>) createTenantResp.getBody().get("data"));

            var body = Map.of(
                    "tenantId", Long.valueOf(tenantId),
                    "contractNumber", "CT-TEST-" + System.nanoTime(),
                    "billingModel", "direct",
                    "effectiveTier", "standard"
            );
            var resp = postRaw(platformAdminToken, "/api/v1/admin/contracts", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        }

        @Test
        @DisplayName("platform_admin 查看合同列表")
        @SuppressWarnings("unchecked")
        void admin_listContracts() {
            var resp = getRaw(platformAdminToken, "/api/v1/admin/contracts");
            assertThat(resp.getStatusCode().value()).isEqualTo(200);
            // API returns List<ContractResponse> directly in data field, not {items:...}
            Object data = resp.getBody().get("data");
            assertThat(data).isInstanceOf(List.class);
            List<Map<String, Object>> items = (List<Map<String, Object>>) data;
            assertThat(items).isNotEmpty();
        }

        @Test
        @DisplayName("platform_admin 更新合同状态")
        @SuppressWarnings("unchecked")
        void admin_updateContractStatus() {
            var listResp = getRaw(platformAdminToken, "/api/v1/admin/contracts");
            assertThat(listResp.getStatusCode().value()).isEqualTo(200);
            List<Map<String, Object>> items = (List<Map<String, Object>>) listResp.getBody().get("data");
            assertThat(items).isNotEmpty();

            String contractId = extractId(items.get(0));
            var body = Map.of("targetStatus", "SUSPENDED");
            var resp = putRaw(platformAdminToken,
                    "/api/v1/admin/contracts/" + contractId + "/status", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
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
            // Need a contractId and grossAmountCents — use contract from seed data
            var contractsResp = getRaw(platformAdminToken, "/api/v1/admin/contracts");
            @SuppressWarnings("unchecked")
            var contracts = (List<Map<String, Object>>) contractsResp.getBody().get("data");
            if (contracts == null || contracts.isEmpty()) return;

            String contractId = extractId(contracts.get(0));
            var body = Map.of(
                    "contractId", Long.valueOf(contractId),
                    "periodStart", "2026-05-01",
                    "periodEnd", "2026-05-31",
                    "grossAmountCents", 100000
            );
            var resp = postRaw(platformAdminToken, "/api/v1/admin/revenue/calculate", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
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
        @SuppressWarnings("unchecked")
        void admin_listFeatureGates() {
            var resp = getRaw(platformAdminToken, "/api/v1/admin/feature-gates");
            assertThat(resp.getStatusCode().value()).isEqualTo(200);
            // API returns List directly, not {items:...}
            Object data = resp.getBody().get("data");
            assertThat(data).isInstanceOf(List.class);
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
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        }

        @Test
        @DisplayName("owner 不能访问 Admin 分润端点")
        void owner_cannotAccessAdminRevenue() {
            var resp = getRaw(ownerToken, "/api/v1/admin/revenue/periods");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        }

        @Test
        @DisplayName("owner 不能访问 Admin 订阅服务管理")
        void owner_cannotAccessAdminSubscriptionServices() {
            var resp = getRaw(ownerToken, "/api/v1/admin/subscription-services");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        }

        @Test
        @DisplayName("worker 可以查看订阅信息（无角色限制）")
        void worker_canViewSubscription() {
            var resp = getRaw(workerToken, "/api/v1/subscription");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        }
    }
}
