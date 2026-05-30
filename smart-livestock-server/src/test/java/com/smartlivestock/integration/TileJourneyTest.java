package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 瓦片端点 e2e 测试。
 * 覆盖 TileAppController（3 端点）、TileController（2 端点）、TileAdminController（5 端点）。
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
        @DisplayName("owner 查看瓦片源")
        void owner_tileSource() {
            var data = getApi(ownerToken, "/api/v1/farms/1/tile-source");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("owner 查看离线地图信息")
        void owner_offlineMap() {
            var data = getApi(ownerToken, "/api/v1/farms/1/offline-map");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("owner 记录瓦片下载日志")
        void owner_tileDownloadLog() {
            var body = Map.of(
                    "zoomLevel", 14,
                    "tileCount", 100
            );
            var resp = postRaw(ownerToken, "/api/v1/farms/1/tile-download-log", body);
            assertThat(resp.getStatusCode().value()).isIn(200, 201);
        }
    }

    @Nested
    @DisplayName("Admin 瓦片端点")
    class AdminTileEndpoints {

        @Test
        @DisplayName("platform_admin 查看瓦片管理状态")
        void admin_tileStatus() {
            var data = getApi(platformAdminToken, "/api/v1/admin/tiles/status");
            assertThat(data).isNotNull();
        }

        @Test
        @DisplayName("platform_admin 查看瓦片区域列表")
        void admin_listRegions() {
            var data = getApi(platformAdminToken, "/api/v1/admin/tiles/regions");
            assertThat(data).containsKey("items");
        }

        @Test
        @DisplayName("platform_admin 查看瓦片生成任务")
        void admin_listTasks() {
            var data = getApi(platformAdminToken, "/api/v1/admin/tiles/tasks");
            assertThat(data).containsKey("items");
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
                    "maxZoom", 14
            );
            var resp = postRaw(platformAdminToken, "/api/v1/admin/tiles/regions", body);
            assertThat(resp.getStatusCode().value()).isIn(200, 201);
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
