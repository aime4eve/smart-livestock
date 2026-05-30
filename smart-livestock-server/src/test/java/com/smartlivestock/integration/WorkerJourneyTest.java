package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 旅程 2.4: 牧工旅程。
 *
 * worker 登录 → 数智孪生(只读) → 告警(仅确认) → 围栏(只读) → 权限边界全面验证
 */
class WorkerJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("Worker 数据读取")
    class WorkerReadData {

        @Test
        @DisplayName("worker 查看牧场列表")
        void worker_listFarms() {
            var data = getApi(workerToken, "/api/v1/farms");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items).isNotEmpty();
        }

        @Test
        @DisplayName("worker 查看牧场 1 牲畜列表")
        void worker_listLivestock() {
            var data = getApi(workerToken, "/api/v1/farms/1/livestock?page=0&size=5");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items).isNotEmpty();
        }

        @Test
        @DisplayName("worker 查看围栏列表（只读）")
        void worker_listFences() {
            var data = getApi(workerToken, "/api/v1/farms/1/fences");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items).isNotEmpty();
        }

        @Test
        @DisplayName("worker 查看告警列表")
        void worker_listAlerts() {
            var data = getApi(workerToken, "/api/v1/farms/1/alerts?page=0&size=10");
            assertThat(data).containsKey("items");
        }

        @Test
        @DisplayName("worker 查看告警详情")
        void worker_getAlertDetail() {
            var listData = getApi(workerToken, "/api/v1/farms/1/alerts?page=0&size=10");
            var items = getItems(listData);
            if (!items.isEmpty()) {
                String alertId = String.valueOf(((Number) items.get(0).get("id")).longValue());
                var detail = getApi(workerToken, "/api/v1/farms/1/alerts/" + alertId);
                assertThat(detail).containsKey("id");
            }
        }

        @Test
        @DisplayName("worker 查看 Dashboard")
        void worker_viewDashboard() {
            var data = getApi(workerToken, "/api/v1/farms/1/dashboard/summary");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("worker 查看地图概览")
        void worker_viewMapOverview() {
            var data = getApi(workerToken, "/api/v1/farms/1/map/overview");
            assertThat(data).isNotNull();
        }
    }

    @Nested
    @DisplayName("Worker 告警操作")
    class WorkerAlertOperations {

        @Test
        @DisplayName("worker 可以确认 PENDING 告警")
        void worker_canAcknowledge() {
            var listData = getApi(workerToken, "/api/v1/farms/1/alerts?page=0&size=50");
            var items = getItems(listData);

            var pending = items.stream()
                    .filter(a -> "PENDING".equals(a.get("status")))
                    .findFirst();
            if (pending.isPresent()) {
                Long alertId = ((Number) pending.get().get("id")).longValue();
                var result = postApi(workerToken,
                        "/api/v1/farms/1/alerts/" + alertId + "/acknowledge", null);
                assertThat(result.get("status")).isEqualTo("ACKNOWLEDGED");
            }
        }
    }

    @Nested
    @DisplayName("Worker 权限禁止（写操作）")
    class WorkerWriteForbidden {

        @Test
        @DisplayName("worker 不能创建牲畜")
        void worker_cannotCreateLivestock() {
            var body = Map.of(
                    "livestockCode", "SL-WORKER-001",
                    "breed", "西门塔尔牛"
            );
            var resp = postRaw(workerToken, "/api/v1/farms/1/livestock", body);
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能创建围栏")
        void worker_cannotCreateFence() {
            var body = Map.of(
                    "name", "Worker非法围栏",
                    "color", "#000000",
                    "vertices", List.of(
                            Map.of("latitude", 28.240, "longitude", 112.845),
                            Map.of("latitude", 28.250, "longitude", 112.845),
                            Map.of("latitude", 28.250, "longitude", 112.855)
                    )
            );
            var resp = postRaw(workerToken, "/api/v1/farms/1/fences", body);
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能删除围栏")
        void worker_cannotDeleteFence() {
            var resp = deleteRaw(workerToken, "/api/v1/farms/1/fences/1");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能处理告警（handle）")
        void worker_cannotHandleAlert() {
            var listData = getApi(workerToken, "/api/v1/farms/1/alerts?page=0&size=50");
            var items = getItems(listData);

            var acknowledged = items.stream()
                    .filter(a -> "ACKNOWLEDGED".equals(a.get("status")))
                    .findFirst();

            if (acknowledged.isPresent()) {
                Long alertId = ((Number) acknowledged.get().get("id")).longValue();
                var resp = postRaw(workerToken,
                        "/api/v1/farms/1/alerts/" + alertId + "/handle", null);
                assertThat(resp.getStatusCode().value()).isIn(403, 409);
            }
        }

        @Test
        @DisplayName("worker 不能归档告警（archive）")
        void worker_cannotArchiveAlert() {
            var listData = getApi(workerToken, "/api/v1/farms/1/alerts?page=0&size=50");
            var items = getItems(listData);

            var handled = items.stream()
                    .filter(a -> "HANDLED".equals(a.get("status")))
                    .findFirst();

            if (handled.isPresent()) {
                Long alertId = ((Number) handled.get().get("id")).longValue();
                var resp = postRaw(workerToken,
                        "/api/v1/farms/1/alerts/" + alertId + "/archive", null);
                assertThat(resp.getStatusCode().value()).isIn(403, 409);
            }
        }

        @Test
        @DisplayName("worker 不能注册设备")
        void worker_cannotRegisterDevice() {
            var body = Map.of(
                    "deviceCode", "DEV-WORKER-001",
                    "deviceType", "TRACKER"
            );
            var resp = postRaw(workerToken, "/api/v1/farms/1/devices", body);
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }
    }

    @Nested
    @DisplayName("Worker 权限禁止（管理端）")
    class WorkerAdminForbidden {

        @Test
        @DisplayName("worker 不能访问 Admin 端点")
        void worker_cannotAccessAdmin() {
            var resp = getRaw(workerToken, "/api/v1/admin/tenants");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能管理租户")
        void worker_cannotAccessTenant() {
            var resp = getRaw(workerToken, "/api/v1/admin/tenants/1");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能查看 Admin 合同")
        void worker_cannotAccessContracts() {
            var resp = getRaw(workerToken, "/api/v1/admin/contracts");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能查看 Admin 分润")
        void worker_cannotAccessRevenue() {
            var resp = getRaw(workerToken, "/api/v1/admin/revenue/periods");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能查看 Admin 订阅")
        void worker_cannotAccessSubscriptions() {
            var resp = getRaw(workerToken, "/api/v1/admin/subscriptions");
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }

        @Test
        @DisplayName("worker 不能创建牧场")
        void worker_cannotCreateFarm() {
            var body = Map.of(
                    "name", "Worker非法牧场",
                    "latitude", 28.25,
                    "longitude", 112.85
            );
            var resp = postRaw(workerToken, "/api/v1/farms", body);
            assertThat(resp.getStatusCode().value()).isIn(403, 401);
        }
    }
}
