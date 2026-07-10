package com.smartlivestock.integration;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * P0: 告警通知中心模型端到端测试。
 * 覆盖旅程：新通知中心模型 + 角色权限。
 *
 * 状态机：ACTIVE → DISMISSED (manual) 或 AUTO_RESOLVED (automatic)
 * Read status tracked per-user via alert_read_status.
 *
 * 每个测试通过 AlertApplicationService 创建独立告警，避免 seed 数据污染。
 */
class AlertStateMachineJourneyTest extends AbstractJourneyTest {

    @org.springframework.beans.factory.annotation.Autowired
    private AlertApplicationService alertApplicationService;

    /** Create a fresh ACTIVE alert for testing. */
    private String createActiveAlert(Long farmId) {
        AlertDto alert = alertApplicationService.createAlert(
                farmId, AlertType.FENCE_BREACH, Severity.WARNING, "测试告警-" + System.nanoTime());
        return String.valueOf(alert.id());
    }

    @Nested
    @DisplayName("通知中心状态转换")
    class NotificationCenterTransitions {

        @Test
        @DisplayName("ACTIVE → dismiss → DISMISSED")
        void active_to_dismissed() {
            String alertId = createActiveAlert(1L);

            var dismissResult = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/dismiss", null);
            assertThat(dismissResult.get("status")).isEqualTo("DISMISSED");
            assertThat(dismissResult.get("resolvedType")).isEqualTo("MANUAL_DISMISS");
        }

        @Test
        @DisplayName("ACTIVE → archive (auto-resolve) → AUTO_RESOLVED")
        void active_to_autoResolved() {
            String alertId = createActiveAlert(1L);

            var archiveResult = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/archive", null);
            assertThat(archiveResult.get("status")).isEqualTo("AUTO_RESOLVED");
            assertThat(archiveResult.get("resolvedType")).isEqualTo("AUTO");
        }

        @Test
        @DisplayName("markRead 端点可用")
        void markRead_endpoint() {
            String alertId = createActiveAlert(1L);

            var readResult = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/read", null);
            assertThat(readResult.get("status")).isEqualTo("ACTIVE");
        }

        @Test
        @DisplayName("batch-read 端点可用")
        void batchRead_endpoint() {
            String alertId1 = createActiveAlert(1L);
            String alertId2 = createActiveAlert(1L);

            var result = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/batch-read",
                    java.util.Map.of("alertIds", java.util.List.of(alertId1, alertId2)));
            assertThat(result.get("count")).isEqualTo(2);
        }
    }

    @Nested
    @DisplayName("角色权限")
    class RolePermissions {

        @Test
        @DisplayName("worker 可以 markRead")
        void workerCanMarkRead() {
            String alertId = createActiveAlert(1L);

            var readResult = postApi(workerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/read", null);
            assertThat(readResult.get("status")).isEqualTo("ACTIVE");
        }

        @Test
        @DisplayName("worker 不能 dismiss 告警")
        void workerCannotDismiss() {
            String alertId = createActiveAlert(1L);

            var resp = postRaw(workerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/dismiss", null);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        }
    }

    @Nested
    @DisplayName("非法状态转换")
    class IllegalTransitions {

        @Test
        @DisplayName("dismiss 已解除的告警返回 409")
        void dismiss_dismissedAlert_returns409() {
            String alertId = createActiveAlert(1L);
            postApi(ownerToken, "/api/v1/farms/1/alerts/" + alertId + "/dismiss", null);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/dismiss", null);
            assertError(resp, HttpStatus.CONFLICT, "STATE_CONFLICT");
        }

        @Test
        @DisplayName("dismiss 已自动解除的告警返回 409")
        void dismiss_autoResolvedAlert_returns409() {
            String alertId = createActiveAlert(1L);
            postApi(ownerToken, "/api/v1/farms/1/alerts/" + alertId + "/archive", null);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/dismiss", null);
            assertError(resp, HttpStatus.CONFLICT, "STATE_CONFLICT");
        }
    }

    @Nested
    @DisplayName("向后兼容端点")
    class LegacyEndpoints {

        @Test
        @DisplayName("旧 /acknowledge 端点仍可调用")
        void legacy_acknowledge() {
            String alertId = createActiveAlert(1L);

            var result = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);
            // Legacy: no-op on alert, status stays ACTIVE
            assertThat(result.get("status")).isEqualTo("ACTIVE");
        }

        @Test
        @DisplayName("旧 /handle 端点重定向到 dismiss")
        void legacy_handle() {
            String alertId = createActiveAlert(1L);

            var result = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/handle", null);
            assertThat(result.get("status")).isEqualTo("DISMISSED");
        }
    }
}
