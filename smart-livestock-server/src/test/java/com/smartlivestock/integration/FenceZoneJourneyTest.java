package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for fence zone CRUD endpoints.
 */
class FenceZoneJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("GET /farms/{farmId}/fence-zones")
    class ListFenceZones {

        @Test
        @DisplayName("owner 列出围栏区域（可为空）")
        void ownerListZones() {
            Map<String, Object> data = getApi(ownerToken,
                    "/api/v1/farms/1/fence-zones");
            assertThat(data).containsKey("items");
            assertThat(data.get("items")).isInstanceOf(List.class);
        }

        @Test
        @DisplayName("无 token 返回 401")
        void noAuthReturns401() {
            var resp = getRawNoAuth("/api/v1/farms/1/fence-zones");
            assertThat(resp.getStatusCode().value()).isEqualTo(401);
        }
    }

    @Nested
    @DisplayName("POST /farms/{farmId}/fence-zones")
    class CreateFenceZone {

        @Test
        @DisplayName("owner 创建围栏区域成功")
        void ownerCreateZone() {
            var body = Map.of(
                    "fenceId", 1,
                    "name", "水源区",
                    "zoneType", "WATER_SOURCE",
                    "vertices", List.of(
                            Map.of("lat", "28.2450", "lng", "112.8510"),
                            Map.of("lat", "28.2460", "lng", "112.8510"),
                            Map.of("lat", "28.2460", "lng", "112.8520"),
                            Map.of("lat", "28.2450", "lng", "112.8520")
                    ),
                    "alertRadius", 30,
                    "severity", "WARNING"
            );
            Map<String, Object> result = postApi(ownerToken,
                    "/api/v1/farms/1/fence-zones", body);
            assertThat(result).containsKeys("id", "fenceId", "name", "zoneType", "farmId");
            assertThat(result.get("name")).isEqualTo("水源区");
            assertThat(result.get("zoneType")).isEqualTo("WATER_SOURCE");
        }

        @Test
        @DisplayName("worker 不能创建围栏区域")
        void workerCannotCreate() {
            var body = Map.of(
                    "fenceId", 1,
                    "name", "test",
                    "zoneType", "TEST",
                    "vertices", List.of(
                            Map.of("lat", "28.2450", "lng", "112.8510"),
                            Map.of("lat", "28.2460", "lng", "112.8510"),
                            Map.of("lat", "28.2460", "lng", "112.8520")
                    )
            );
            var resp = postRaw(workerToken,
                    "/api/v1/farms/1/fence-zones", body);
            assertThat(resp.getStatusCode().value()).isEqualTo(403);
        }
    }
}
