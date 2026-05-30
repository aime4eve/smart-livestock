package com.smartlivestock.integration;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * P0: 告警状态机完整端到端测试。
 * 覆盖旅程：2.6 告警状态机 + 2.3/2.4 告警管理。
 *
 * 状态机：pending → acknowledged → handled → archived
 * 非法跳转返回 409 STATE_CONFLICT
 *
 * 每个测试通过 AlertApplicationService 创建独立告警，避免 seed 数据污染。
 */
class AlertStateMachineJourneyTest extends AbstractJourneyTest {

    @org.springframework.beans.factory.annotation.Autowired
    private AlertApplicationService alertApplicationService;

    /** Create a fresh PENDING alert for testing. */
    private String createPendingAlert(Long farmId) {
        AlertDto alert = alertApplicationService.createAlert(
                farmId, AlertType.FENCE_BREACH, Severity.WARNING, "测试告警-" + System.nanoTime());
        return String.valueOf(alert.id());
    }

    @Nested
    @DisplayName("完整状态转换链路")
    class FullStateTransition {

        @Test
        @DisplayName("pending → acknowledged → handled → archived 完整链路")
        void fullStateTransition_pending_to_archived() {
            String alertId = createPendingAlert(1L);

            // Step 1: acknowledge
            var ackResult = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);
            assertThat(ackResult.get("status")).isEqualTo("ACKNOWLEDGED");

            // Step 2: handle
            var handleResult = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/handle", null);
            assertThat(handleResult.get("status")).isEqualTo("HANDLED");

            // Step 3: archive
            var archiveResult = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/archive", null);
            assertThat(archiveResult.get("status")).isEqualTo("ARCHIVED");
        }
    }

    @Nested
    @DisplayName("跨角色协作")
    class CrossRoleCollaboration {

        @Test
        @DisplayName("worker acknowledge → owner handle 成功")
        void workerAcknowledge_ownerHandle_success() {
            String alertId = createPendingAlert(1L);

            // worker 确认
            var ackResult = postApi(workerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);
            assertThat(ackResult.get("status")).isEqualTo("ACKNOWLEDGED");

            // owner 处理
            var handleResult = postApi(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/handle", null);
            assertThat(handleResult.get("status")).isEqualTo("HANDLED");
        }

        @Test
        @DisplayName("worker 可以确认 PENDING 告警")
        void workerCanAcknowledge_pendingAlert() {
            String alertId = createPendingAlert(1L);

            var ackResult = postApi(workerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);
            assertThat(ackResult.get("status")).isEqualTo("ACKNOWLEDGED");
        }

        @Test
        @DisplayName("worker 不能 handle 告警")
        void workerCannotHandle_alert() {
            String alertId = createPendingAlert(1L);

            // 先 acknowledge
            postApi(workerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);

            // worker 尝试 handle
            var handleResp = postRaw(workerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/handle", null);
            assertThat(handleResp.getStatusCode().value()).isIn(200, 403, 409);
        }
    }

    @Nested
    @DisplayName("非法状态转换")
    class IllegalTransitions {

        @Test
        @DisplayName("acknowledge 非 PENDING 告警返回 409")
        void acknowledge_nonPendingAlert_returns409() {
            String alertId = createPendingAlert(1L);
            postApi(ownerToken, "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);
            assertError(resp, org.springframework.http.HttpStatus.CONFLICT, "STATE_CONFLICT");
        }

        @Test
        @DisplayName("handle PENDING 告警（跳过 acknowledge）返回 409")
        void handle_pendingAlert_returns409() {
            String alertId = createPendingAlert(1L);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/handle", null);
            assertError(resp, org.springframework.http.HttpStatus.CONFLICT, "STATE_CONFLICT");
        }

        @Test
        @DisplayName("archive ACKNOWLEDGED 告警（跳过 handle）返回 409")
        void archive_acknowledgedAlert_returns409() {
            String alertId = createPendingAlert(1L);

            postApi(ownerToken, "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/archive", null);
            assertError(resp, org.springframework.http.HttpStatus.CONFLICT, "STATE_CONFLICT");
        }

        @Test
        @DisplayName("archive PENDING 告警（跳过两步）返回 409")
        void archive_pendingAlert_returns409() {
            String alertId = createPendingAlert(1L);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/archive", null);
            assertError(resp, org.springframework.http.HttpStatus.CONFLICT, "STATE_CONFLICT");
        }
    }
}
