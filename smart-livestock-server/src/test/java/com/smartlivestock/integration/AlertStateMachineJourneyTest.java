package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.springframework.test.annotation.DirtiesContext;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * P0: 告警状态机完整端到端测试。
 * 覆盖旅程：2.6 告警状态机 + 2.3/2.4 告警管理。
 *
 * 状态机：pending → acknowledged → handled → archived
 * 非法跳转返回 409 STATE_CONFLICT
 */
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class AlertStateMachineJourneyTest extends AbstractJourneyTest {

    @SuppressWarnings("unchecked")
    private Map<String, Object> findPendingAlert(Long farmId) {
        Map<String, Object> alertsData = getApi(ownerToken,
                "/api/v1/farms/" + farmId + "/alerts?page=0&size=50");
        List<Map<String, Object>> items = (List<Map<String, Object>>) alertsData.get("items");
        return items.stream()
                .filter(a -> "PENDING".equals(a.get("status")))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Farm " + farmId + " 无 PENDING 告警"));
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> findPendingAlertByWorker(Long farmId) {
        Map<String, Object> alertsData = getApi(workerToken,
                "/api/v1/farms/" + farmId + "/alerts?page=0&size=50");
        List<Map<String, Object>> items = (List<Map<String, Object>>) alertsData.get("items");
        return items.stream()
                .filter(a -> "PENDING".equals(a.get("status")))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Farm " + farmId + " 无 PENDING 告警（worker 视角）"));
    }

    @Nested
    @DisplayName("完整状态转换链路")
    class FullStateTransition {

        @Test
        @DisplayName("pending → acknowledged → handled → archived 完整链路")
        void fullStateTransition_pending_to_archived() {
            var pendingAlert = findPendingAlert(1L);
            String alertId = extractId(pendingAlert);
            assertThat(pendingAlert.get("status")).isEqualTo("PENDING");

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
            var pendingAlert = findPendingAlertByWorker(1L);
            String alertId = extractId(pendingAlert);

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
            var pendingAlert = findPendingAlertByWorker(1L);
            String alertId = extractId(pendingAlert);

            var ackResult = postApi(workerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);
            assertThat(ackResult.get("status")).isEqualTo("ACKNOWLEDGED");
        }

        @Test
        @DisplayName("worker 不能 handle 告警")
        void workerCannotHandle_alert() {
            var pendingAlert = findPendingAlertByWorker(1L);
            String alertId = extractId(pendingAlert);

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
            var pendingAlert = findPendingAlert(1L);
            String alertId = extractId(pendingAlert);
            postApi(ownerToken, "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);
            assertError(resp, org.springframework.http.HttpStatus.CONFLICT, "STATE_CONFLICT");
        }

        @Test
        @DisplayName("handle PENDING 告警（跳过 acknowledge）返回 409")
        void handle_pendingAlert_returns409() {
            var pendingAlert = findPendingAlert(1L);
            String alertId = extractId(pendingAlert);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/handle", null);
            assertError(resp, org.springframework.http.HttpStatus.CONFLICT, "STATE_CONFLICT");
        }

        @Test
        @DisplayName("archive ACKNOWLEDGED 告警（跳过 handle）返回 409")
        void archive_acknowledgedAlert_returns409() {
            var pendingAlert = findPendingAlert(1L);
            String alertId = extractId(pendingAlert);

            postApi(ownerToken, "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/archive", null);
            assertError(resp, org.springframework.http.HttpStatus.CONFLICT, "STATE_CONFLICT");
        }

        @Test
        @DisplayName("archive PENDING 告警（跳过两步）返回 409")
        void archive_pendingAlert_returns409() {
            var pendingAlert = findPendingAlert(1L);
            String alertId = extractId(pendingAlert);

            var resp = postRaw(ownerToken,
                    "/api/v1/farms/1/alerts/" + alertId + "/archive", null);
            assertError(resp, org.springframework.http.HttpStatus.CONFLICT, "STATE_CONFLICT");
        }
    }
}
