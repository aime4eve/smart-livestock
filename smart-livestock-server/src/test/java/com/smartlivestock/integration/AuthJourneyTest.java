package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * P0: 认证 API 端到端测试。
 * 覆盖旅程：所有旅程的入口（登录/认证）。
 */
class AuthJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("登录成功场景")
    class LoginSuccess {

        @Test
        @DisplayName("platform_admin 登录成功返回 token")
        void platformAdminLogin() {
            assertThat(platformAdminToken).isNotNull().isNotBlank();
        }

        @Test
        @DisplayName("b2b_admin 登录成功返回 token")
        void b2bAdminLogin() {
            assertThat(b2bAdminToken).isNotNull().isNotBlank();
        }

        @Test
        @DisplayName("owner 登录成功返回 token")
        void ownerLogin() {
            assertThat(ownerToken).isNotNull().isNotBlank();
        }

        @Test
        @DisplayName("worker 登录成功返回 token")
        void workerLogin() {
            assertThat(workerToken).isNotNull().isNotBlank();
        }

        @Test
        @DisplayName("登录响应包含用户信息")
        void loginResponseContainsUserInfo() {
            var resp = loginRaw("13800138000", "123");
            assertOk(resp);

            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) resp.getBody().get("data");
            assertThat(data).containsKey("accessToken");
            assertThat(data).containsKey("user");

            @SuppressWarnings("unchecked")
            Map<String, Object> user = (Map<String, Object>) data.get("user");
            assertThat(user.get("role")).isEqualTo("OWNER");
        }
    }

    @Nested
    @DisplayName("登录失败场景")
    class LoginFailure {

        @Test
        @DisplayName("错误密码返回 401")
        void wrongPassword_returns401() {
            var resp = loginRaw("13800138000", "wrong-password");
            assertError(resp, org.springframework.http.HttpStatus.UNAUTHORIZED, "AUTH_INVALID_TOKEN");
        }

        @Test
        @DisplayName("不存在的手机号返回 401")
        void nonexistentPhone_returns401() {
            var resp = loginRaw("99999999999", "123");
            assertError(resp, org.springframework.http.HttpStatus.UNAUTHORIZED, "AUTH_INVALID_TOKEN");
        }

        @Test
        @DisplayName("空密码返回 401 或 400")
        void emptyPassword_returnsError() {
            var resp = loginRaw("13800138000", "");
            assertThat(resp.getStatusCode().value()).isIn(400, 401);
        }
    }

    @Nested
    @DisplayName("Token 验证场景")
    class TokenValidation {

        @Test
        @DisplayName("无 token 访问受保护端点返回 401")
        void noToken_returns401() {
            var resp = getRawNoAuth("/api/v1/farms");
            assertThat(resp.getStatusCode()).isEqualTo(org.springframework.http.HttpStatus.UNAUTHORIZED);
        }

        @Test
        @DisplayName("有效 token 访问受保护端点返回 200")
        void validToken_succeeds() {
            var data = getApi(ownerToken, "/api/v1/farms");
            assertThat(data).containsKey("items");
        }

        @Test
        @DisplayName("伪造 token 访问受保护端点返回 401")
        void invalidToken_returns401() {
            var resp = getRaw("fake-jwt-token-12345", "/api/v1/farms");
            assertThat(resp.getStatusCode()).isEqualTo(org.springframework.http.HttpStatus.UNAUTHORIZED);
        }
    }
}
