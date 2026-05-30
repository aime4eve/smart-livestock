package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 旅程 2.3 部分: 牧场主牲畜 + 设备 + GPS 旅程。
 *
 * owner → 牲畜CRUD → 设备管理 → 安装 → GPS日志 → 牲畜详情
 */
class OwnerLivestockDeviceJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("Owner 牲畜管理")
    class OwnerLivestock {

        @Test
        @DisplayName("owner 查看牧场 1 牲畜列表 total=50")
        void owner_listLivestock_farm1() {
            var data = getApi(ownerToken, "/api/v1/farms/1/livestock?page=0&size=1");
            assertThat(data.get("total")).isEqualTo(50);
        }

        @Test
        @DisplayName("owner 查看牧场 2 牲畜列表 total=10")
        void owner_listLivestock_farm2() {
            var data = getApi(ownerToken, "/api/v1/farms/2/livestock?page=0&size=1");
            assertThat(data.get("total")).isEqualTo(10);
        }

        @Test
        @DisplayName("owner 查看牲畜详情")
        void owner_getLivestockDetail() {
            var listData = getApi(ownerToken, "/api/v1/farms/1/livestock?page=0&size=1");
            var items = getItems(listData);
            assertThat(items).isNotEmpty();

            String livestockId = extractId(items.get(0));
            var detail = getApi(ownerToken, "/api/v1/farms/1/livestock/" + livestockId);
            assertThat(detail).containsKey("id");
            assertThat(detail).containsKey("livestockCode");
        }

        @Test
        @DisplayName("owner 创建牲畜成功")
        void owner_createLivestock_success() {
            var body = Map.of(
                    "livestockCode", "SL-E2E-001",
                    "breed", "西门塔尔牛",
                    "healthStatus", "HEALTHY"
            );
            var resp = postRaw(ownerToken, "/api/v1/farms/1/livestock", body);
            assertThat(resp.getStatusCode().value()).isIn(200, 201);
        }

        @Test
        @DisplayName("owner 更新牲畜信息成功")
        void owner_updateLivestock_success() {
            var listData = getApi(ownerToken, "/api/v1/farms/1/livestock?page=0&size=1");
            var items = getItems(listData);
            assertThat(items).isNotEmpty();

            String livestockId = extractId(items.get(0));
            var body = Map.of(
                    "breed", "安格斯牛",
                    "healthStatus", "HEALTHY"
            );
            var resp = putRaw(ownerToken, "/api/v1/farms/1/livestock/" + livestockId, body);
            assertThat(resp.getStatusCode().value()).isIn(200, 204);
        }

        @Test
        @DisplayName("owner 牲畜列表返回完整数据")
        void owner_livestockListAll() {
            var data = getApi(ownerToken, "/api/v1/farms/1/livestock?page=0&size=100");
            assertThat(((Number) data.get("total")).longValue()).isEqualTo(50);

            @SuppressWarnings("unchecked")
            var items = (List<Map<String, Object>>) data.get("items");
            assertThat(items).hasSize(50);
        }
    }

    @Nested
    @DisplayName("Owner 设备管理")
    class OwnerDevice {

        @Test
        @DisplayName("owner 查看牧场设备列表")
        void owner_listDevices() {
            var data = getApi(ownerToken, "/api/v1/farms/1/devices");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items).isNotEmpty();
        }

        @Test
        @DisplayName("owner 查看设备详情")
        void owner_getDeviceDetail() {
            var data = getApi(ownerToken, "/api/v1/farms/1/devices");
            var items = getItems(data);
            assertThat(items).isNotEmpty();

            String deviceId = extractId(items.get(0));
            var detail = getApi(ownerToken, "/api/v1/farms/1/devices/" + deviceId);
            assertThat(detail).containsKey("id");
            assertThat(detail).containsKey("deviceCode");
        }

        @Test
        @DisplayName("owner 注册新设备")
        void owner_registerDevice() {
            var body = Map.of(
                    "deviceCode", "DEV-E2E-001",
                    "deviceType", "TRACKER"
            );
            var resp = postRaw(ownerToken, "/api/v1/farms/1/devices", body);
            assertThat(resp.getStatusCode().value()).isIn(200, 201);
        }
    }

    @Nested
    @DisplayName("Owner 安装管理")
    class OwnerInstallation {

        @Test
        @DisplayName("owner 查看安装记录列表")
        void owner_listInstallations() {
            var data = getApi(ownerToken, "/api/v1/farms/1/installations");
            assertThat(data).containsKey("items");
        }

        @Test
        @DisplayName("owner 查看设备 License 列表")
        void owner_listDeviceLicenses() {
            var data = getApi(ownerToken, "/api/v1/device-licenses");
            assertThat(data).containsKey("items");
        }
    }

    @Nested
    @DisplayName("Owner GPS 日志")
    class OwnerGpsLog {

        @Test
        @DisplayName("owner 查看最新 GPS 日志")
        void owner_latestGpsLogs() {
            var data = getApi(ownerToken, "/api/v1/farms/1/gps-logs/latest");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("owner 查看指定牲畜 GPS 日志")
        void owner_livestockGpsLogs() {
            var listData = getApi(ownerToken, "/api/v1/farms/1/livestock?page=0&size=1");
            var items = getItems(listData);
            assertThat(items).isNotEmpty();

            String livestockId = extractId(items.get(0));
            var resp = getRaw(ownerToken, "/api/v1/farms/1/livestock/" + livestockId + "/gps-logs");
            assertThat(resp.getStatusCode().value()).isIn(200, 404);
        }
    }
}
