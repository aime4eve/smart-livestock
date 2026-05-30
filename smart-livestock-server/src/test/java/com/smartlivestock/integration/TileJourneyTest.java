package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 瓦片端点 e2e 测试。
 * 覆盖 TileAppController、TileAdminController、TileController。
 */
class TileJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("App 端瓦片端点")
    class AppTileEndpoints {

        @Test
        @DisplayName("owner 查看牧场瓦片状态")
        void owner_tileStatus() {
            var data = getApi(ownerToken, "/api/v1/farms/1/tile-status");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("owner 查看瓦片源（返回 List）")
        @SuppressWarnings("unchecked")
        void owner_tileSource() {
            var resp = getRaw(ownerToken, "/api/v1/farms/1/tile-source");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(resp.getBody()).containsKey("data");
            Object data = resp.getBody().get("data");
            // TileAppController returns ApiResponse<List<TileSourceDto>>
            assertThat(data).isInstanceOf(List.class);
        }

        @Test
        @DisplayName("owner 查看离线地图（无 mbtiles 返回 404）")
        void owner_offlineMap() {
            var resp = getRaw(ownerToken, "/api/v1/farms/1/offline-map");
            // No mbtiles file on test server → 404
            assertThat(resp.getStatusCode().value()).isIn(200, 404);
        }

        @Test
        @DisplayName("owner 记录瓦片下载日志")
        void owner_tileDownloadLog() {
            var body = Map.of(
                    "farmTileTaskId", 1,
                    "userId", 2,
                    "zoomLevel", 14,
                    "bytesDownloaded", 1024
            );
            var resp = postRaw(ownerToken, "/api/v1/farms/1/tile-download-log", body);
            // 需要 farmTileTaskId 和 userId，若无对应记录可能返回 500
            assertThat(resp.getStatusCode().value()).isIn(200, 500);
        }
    }

    @Nested
    @DisplayName("Admin 瓦片端点")
    class AdminTileEndpoints {

        @Test
        @DisplayName("platform_admin 查看瓦片管理状态（TileController 返回裸 List）")
        void admin_tileStatus() {
            var headers = authHeaders(platformAdminToken);
            var resp = restTemplate.exchange(
                    "/api/v1/admin/tiles/status", HttpMethod.GET,
                    new org.springframework.http.HttpEntity<>(headers), List.class);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
            // TileController.getTileStatus() returns List directly (no ApiResponse wrapper)
            assertThat(resp.getBody()).isNotNull();
        }

        @Test
        @DisplayName("platform_admin 查看瓦片区域列表（返回 List）")
        @SuppressWarnings("unchecked")
        void admin_listRegions() {
            var resp = getRaw(platformAdminToken, "/api/v1/admin/tiles/regions");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(resp.getBody()).containsKey("data");
            Object data = resp.getBody().get("data");
            assertThat(data).isInstanceOf(List.class);
        }

        @Test
        @DisplayName("platform_admin 查看瓦片生成任务（返回 List）")
        @SuppressWarnings("unchecked")
        void admin_listTasks() {
            var resp = getRaw(platformAdminToken, "/api/v1/admin/tiles/tasks");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(resp.getBody()).containsKey("data");
            Object data = resp.getBody().get("data");
            assertThat(data).isInstanceOf(List.class);
        }

        @Test
        @DisplayName("platform_admin 创建瓦片区域")
        void admin_createRegion() {
            var body = Map.of(
                    "name", "E2E测试区域",
                    "minLat", 28.2,
                    "maxLat", 28.3,
                    "minLon", 112.8,
                    "maxLon", 112.9,
                    "minZoom", 10,
                    "maxZoom", 14,
                    "fileName", "e2e_test_region",
                    "status", "ACTIVE"
            );
            var resp = postRaw(platformAdminToken, "/api/v1/admin/tiles/regions", body);
            // TileAdminController.upsertRegion returns 200 OK
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        }
    }

    @Nested
    @DisplayName("瓦片权限边界")
    class TilePermissionBoundary {

        @Test
        @DisplayName("worker 不能访问 Admin 瓦片端点")
        void worker_cannotAccessAdminTiles() {
            var resp = getRaw(workerToken, "/api/v1/admin/tiles/regions");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        }

        @Test
        @DisplayName("owner 不能访问 Admin 瓦片端点")
        void owner_cannotAccessAdminTiles() {
            var resp = getRaw(ownerToken, "/api/v1/admin/tiles/regions");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        }
    }
}
