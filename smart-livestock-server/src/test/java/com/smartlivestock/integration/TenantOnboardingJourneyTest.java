package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * P0: 角色创建链 + 租户 CRUD 端到端测试。
 * 覆盖旅程：2.1 平台入驻 + 2.5 角色创建链。
 *
 * 核心链路：platform_admin 创建租户 → 创建用户 → 新用户登录 → 查询验证
 */
class TenantOnboardingJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("完整入驻链路")
    class FullOnboardingChain {

        @Test
        @DisplayName("platform_admin → 创建租户 → 创建用户 → 新用户登录 → 查询验证")
        void fullOnboardingChain() {
            // Step 1: platform_admin 创建租户
            var createTenantResp = postRaw(platformAdminToken,
                    "/api/v1/admin/tenants",
                    Map.of("name", "测试租户E2E", "contactName", "张三", "contactPhone", "13800001111"));
            assertCreated(createTenantResp);
            @SuppressWarnings("unchecked")
            Map<String, Object> tenantData = (Map<String, Object>) createTenantResp.getBody().get("data");
            String newTenantId = extractId(tenantData);
            assertThat(newTenantId).isNotNull();

            // Step 2: platform_admin 查询租户列表 → 包含新租户
            var tenantList = getApi(platformAdminToken, "/api/v1/admin/tenants");
            var items = getItems(tenantList);
            assertThat(items).anyMatch(t -> newTenantId.equals(extractId(t)));

            // Step 3: platform_admin 创建 b2b_admin 用户并关联新租户
            var createUserResp = postRaw(platformAdminToken,
                    "/api/v1/admin/users",
                    Map.of("phone", "13800002222", "name", "测试B2B管理员", "role", "B2B_ADMIN", "tenantId", newTenantId, "password", "Test@123"));
            assertCreated(createUserResp);
            @SuppressWarnings("unchecked")
            Map<String, Object> userData = (Map<String, Object>) createUserResp.getBody().get("data");
            String newUserId = extractId(userData);
            assertThat(newUserId).isNotNull();

            // Step 4: 用新 b2b_admin 登录
            String newB2bToken = login("13800002222", "Test@123");
            assertThat(newB2bToken).isNotNull().isNotBlank();

            // Step 5: platform_admin 查询租户详情
            var tenantDetail = getApi(platformAdminToken, "/api/v1/admin/tenants/" + newTenantId);
            assertThat(extractId(tenantDetail)).isEqualTo(newTenantId);
            assertThat(tenantDetail).containsKey("userCount");
        }
    }

    @Nested
    @DisplayName("租户 CRUD 验证")
    class TenantCrud {

        @Test
        @DisplayName("创建租户缺少 name 返回 400")
        void createTenant_missingName_returns400() {
            var resp = postRaw(platformAdminToken,
                    "/api/v1/admin/tenants",
                    Map.of("name", "", "contactName", "张三"));
            assertError(resp, org.springframework.http.HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
        }

        @Test
        @DisplayName("更新租户成功")
        void updateTenant_success() {
            var createResp = postRaw(platformAdminToken,
                    "/api/v1/admin/tenants",
                    Map.of("name", "待更新租户", "contactName", "李四", "contactPhone", "13800003333"));
            assertCreated(createResp);
            @SuppressWarnings("unchecked")
            String tenantId = extractId((Map<String, Object>) createResp.getBody().get("data"));

            var updateResp = putRaw(platformAdminToken,
                    "/api/v1/admin/tenants/" + tenantId,
                    Map.of("name", "已更新租户", "contactName", "李四更新"));
            assertOk(updateResp);
            @SuppressWarnings("unchecked")
            Map<String, Object> updated = (Map<String, Object>) updateResp.getBody().get("data");
            assertThat(updated.get("name")).isEqualTo("已更新租户");
        }

        @Test
        @DisplayName("更新租户 phase 为 batch")
        void updateTenantPhase_toBatch() {
            var createResp = postRaw(platformAdminToken,
                    "/api/v1/admin/tenants",
                    Map.of("name", "Phase测试租户", "contactName", "王五", "contactPhone", "13800004444"));
            assertCreated(createResp);
            @SuppressWarnings("unchecked")
            String tenantId = extractId((Map<String, Object>) createResp.getBody().get("data"));

            var updateResp = putRaw(platformAdminToken,
                    "/api/v1/admin/tenants/" + tenantId + "/phase",
                    Map.of("phase", "batch"));
            assertOk(updateResp);
        }

        @Test
        @DisplayName("查询不存在的租户返回 404")
        void getNonexistentTenant_returns404() {
            var resp = getRaw(platformAdminToken, "/api/v1/admin/tenants/999999");
            assertError(resp, org.springframework.http.HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
        }

        @Test
        @DisplayName("查询租户下的牧场列表")
        void listTenantFarms_success() {
            var data = getApi(platformAdminToken, "/api/v1/admin/tenants/1/farms");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items).isNotEmpty();
        }
    }

    @Nested
    @DisplayName("用户管理验证")
    class UserCrud {

        @Test
        @DisplayName("创建用户重复手机号返回 409")
        void createUser_duplicatePhone_returns409() {
            var resp = postRaw(platformAdminToken,
                    "/api/v1/admin/users",
                    Map.of("phone", "13800138000", "name", "重复用户", "role", "OWNER", "tenantId", "1"));
            assertError(resp, org.springframework.http.HttpStatus.CONFLICT, "DUPLICATE_RESOURCE");
        }

        @Test
        @DisplayName("创建用户无效 role 返回 400")
        void createUser_invalidRole_returns400() {
            var resp = postRaw(platformAdminToken,
                    "/api/v1/admin/users",
                    Map.of("phone", "13800005555", "name", "无效角色用户", "role", "INVALID_ROLE", "tenantId", "1"));
            assertError(resp, org.springframework.http.HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
        }

        @Test
        @DisplayName("重置用户密码后可用新密码登录")
        void resetPassword_thenLoginWithNew() {
            var createResp = postRaw(platformAdminToken,
                    "/api/v1/admin/users",
                    Map.of("phone", "13800006666", "name", "密码测试用户", "role", "OWNER", "tenantId", "1", "password", "Old@123"));
            assertCreated(createResp);
            @SuppressWarnings("unchecked")
            String userId = extractId((Map<String, Object>) createResp.getBody().get("data"));

            var resetResp = postRaw(platformAdminToken,
                    "/api/v1/admin/users/" + userId + "/reset-password",
                    Map.of("newPassword", "New@456"));
            assertOk(resetResp);

            String newToken = login("13800006666", "New@456");
            assertThat(newToken).isNotNull();
        }
    }

    @Nested
    @DisplayName("权限边界验证")
    class PermissionBoundary {

        @Test
        @DisplayName("b2b_admin 不能创建租户返回 403")
        void b2bAdmin_cannotCreateTenant_returns403() {
            var resp = postRaw(b2bAdminToken,
                    "/api/v1/admin/tenants",
                    Map.of("name", "非法创建", "contactName", "非法", "contactPhone", "13800007777"));
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("owner 不能创建用户返回 403")
        void owner_cannotCreateUser_returns403() {
            var resp = postRaw(ownerToken,
                    "/api/v1/admin/users",
                    Map.of("phone", "13800008888", "name", "非法用户", "role", "OWNER", "tenantId", "1"));
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能创建用户返回 403")
        void worker_cannotCreateUser_returns403() {
            var resp = postRaw(workerToken,
                    "/api/v1/admin/users",
                    Map.of("phone", "13800009999", "name", "非法用户", "role", "WORKER", "tenantId", "1"));
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }
    }

    @Nested
    @DisplayName("API Key 管理")
    class ApiKeyManagement {

        @Test
        @DisplayName("platform_admin 查看 API Key 列表")
        void platformAdmin_listApiKeys() {
            var data = getApi(platformAdminToken, "/api/v1/admin/api-keys");
            assertThat(data).containsKey("items");
        }

        @Test
        @DisplayName("platform_admin 创建 API Key")
        void platformAdmin_createApiKey() {
            var body = Map.of(
                    "name", "E2E测试Key",
                    "role", "API_CONSUMER",
                    "tenantId", 1
            );
            var resp = postRaw(platformAdminToken, "/api/v1/admin/api-keys", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
            assertThat(resp.getBody()).isNotNull();
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) resp.getBody().get("data");
            assertThat(data).containsKey("rawKey");
            assertThat(data).containsKey("prefix");
        }

        @Test
        @DisplayName("platform_admin 更新 API Key 状态（禁用）")
        void platformAdmin_disableApiKey() {
            var createResp = postRaw(platformAdminToken, "/api/v1/admin/api-keys",
                    Map.of("name", "待禁用Key", "role", "API_CONSUMER", "tenantId", 1));
            assertThat(createResp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
            @SuppressWarnings("unchecked")
            String keyId = extractId((Map<String, Object>) createResp.getBody().get("data"));

            var body = Map.of("status", "disabled");
            var resp = putRaw(platformAdminToken,
                    "/api/v1/admin/api-keys/" + keyId + "/status", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        }

        @Test
        @DisplayName("owner 不能访问 API Key 管理端点")
        void owner_cannotAccessApiKeyAdmin() {
            var resp = getRaw(ownerToken, "/api/v1/admin/api-keys");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        }
    }

    @Nested
    @DisplayName("租户启停（Stub）")
    class TenantStatusStub {

        @Test
        @DisplayName("platform_admin 更新租户状态（stub: active → disabled）")
        void updateTenantStatus_disabled() {
            var createResp = postRaw(platformAdminToken,
                    "/api/v1/admin/tenants",
                    Map.of("name", "启停测试租户", "contactName", "赵六", "contactPhone", "13700100000"));
            assertCreated(createResp);
            @SuppressWarnings("unchecked")
            String tenantId = extractId((Map<String, Object>) createResp.getBody().get("data"));

            var resp = putRaw(platformAdminToken,
                    "/api/v1/admin/tenants/" + tenantId + "/status",
                    Map.of("status", "disabled"));
            assertOk(resp);
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) resp.getBody().get("data");
            assertThat(data.get("status")).isEqualTo("disabled");
        }

        @Test
        @DisplayName("更新租户状态无效值返回 400")
        void updateTenantStatus_invalidStatus_returns400() {
            var createResp = postRaw(platformAdminToken,
                    "/api/v1/admin/tenants",
                    Map.of("name", "状态测试租户2", "contactName", "钱七", "contactPhone", "13700100001"));
            assertCreated(createResp);
            @SuppressWarnings("unchecked")
            String tenantId = extractId((Map<String, Object>) createResp.getBody().get("data"));

            var resp = putRaw(platformAdminToken,
                    "/api/v1/admin/tenants/" + tenantId + "/status",
                    Map.of("status", "invalid_status"));
            assertError(resp, HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
        }

        @Test
        @DisplayName("owner 不能更新租户状态")
        void owner_cannotUpdateTenantStatus() {
            var resp = putRaw(ownerToken,
                    "/api/v1/admin/tenants/1/status",
                    Map.of("status", "disabled"));
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        }
    }
}
