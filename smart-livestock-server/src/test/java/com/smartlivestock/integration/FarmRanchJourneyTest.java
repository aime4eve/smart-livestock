package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer.OrderAnnotation;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * P1: 牧场 CRUD + 围栏 API + 权限边界 端到端测试。
 * 覆盖旅程：2.3 牧场主旅程（围栏/牲畜） + 2.2 B端管理旅程（牧场列表）。
 */
class FarmRanchJourneyTest extends AbstractJourneyTest {

    @Nested
    @DisplayName("Owner 牧场数据查询")
    class OwnerFarmData {

        @Test
        @DisplayName("owner 查看自己的牧场列表")
        void owner_listFarms_success() {
            var data = getApi(ownerToken, "/api/v1/farms");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items).isNotEmpty();
        }

        @Test
        @DisplayName("owner 查看牧场 1 牲畜 total=50")
        void owner_listFarm1Livestock() {
            var data = getApi(ownerToken, "/api/v1/farms/1/livestock?page=0&size=1");
            assertThat(data.get("total")).isEqualTo(50);
        }

        @Test
        @DisplayName("owner 查看牧场 2 牲畜 total=10")
        void owner_listFarm2Livestock() {
            var data = getApi(ownerToken, "/api/v1/farms/2/livestock?page=0&size=1");
            assertThat(data.get("total")).isEqualTo(10);
        }

        @Test
        @DisplayName("owner 查看牧场围栏")
        void owner_listFences_forFarm() {
            var data = getApi(ownerToken, "/api/v1/farms/1/fences");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items.size()).isGreaterThanOrEqualTo(3);
        }
    }

    @Nested
    @DisplayName("Owner 围栏 CRUD")
    class OwnerFenceCrud {

        @Test
        @DisplayName("owner 创建围栏成功")
        void owner_createFence_success() {
            var body = Map.of(
                    "name", "E2E测试围栏",
                    "color", "#FF5733",
                    "vertices", List.of(
                            Map.of("latitude", 28.240, "longitude", 112.845),
                            Map.of("latitude", 28.250, "longitude", 112.845),
                            Map.of("latitude", 28.250, "longitude", 112.855),
                            Map.of("latitude", 28.240, "longitude", 112.855)
                    )
            );
            var resp = postRaw(ownerToken, "/api/v1/farms/1/fences", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        }

        @Test
        @DisplayName("owner 删除围栏成功")
        void owner_deleteFence_success() {
            var data = getApi(ownerToken, "/api/v1/farms/1/fences");
            var items = getItems(data);
            assertThat(items).isNotEmpty();

            @SuppressWarnings("unchecked")
            String fenceId = extractId(items.get(items.size() - 1));

            var resp = deleteRaw(ownerToken, "/api/v1/farms/1/fences/" + fenceId);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        }

        @Test
        @DisplayName("owner 更新围栏名称和颜色")
        void owner_updateFence_success() {
            var createBody = Map.of(
                    "name", "待更新围栏",
                    "color", "#000000",
                    "vertices", List.of(
                            Map.of("latitude", 28.240, "longitude", 112.845),
                            Map.of("latitude", 28.250, "longitude", 112.845),
                            Map.of("latitude", 28.250, "longitude", 112.855)
                    )
            );
            var createResp = postRaw(ownerToken, "/api/v1/farms/1/fences", createBody);
            assertThat(createResp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
            @SuppressWarnings("unchecked")
            String fenceId = extractId((Map<String, Object>) createResp.getBody().get("data"));

            var updateBody = Map.of(
                    "name", "已更新围栏",
                    "color", "#00FF00",
                    "vertices", List.of(
                            Map.of("lat", 28.241, "lng", 112.846),
                            Map.of("lat", 28.251, "lng", 112.846),
                            Map.of("lat", 28.251, "lng", 112.856)
                    )
            );
            var updateResp = putRaw(ownerToken, "/api/v1/farms/1/fences/" + fenceId, updateBody);
            assertThat(updateResp.getStatusCode()).isEqualTo(HttpStatus.OK);
            @SuppressWarnings("unchecked")
            Map<String, Object> updated = (Map<String, Object>) updateResp.getBody().get("data");
            assertThat(updated.get("name")).isEqualTo("已更新围栏");
        }
    }

    @Nested
    @DisplayName("Worker 权限边界")
    class WorkerPermission {

        @Test
        @DisplayName("worker 不能创建围栏")
        void worker_cannotCreateFence_returnsForbidden() {
            var body = Map.of(
                    "name", "非法围栏",
                    "color", "#000000",
                    "vertices", List.of(
                            Map.of("latitude", 28.240, "longitude", 112.845),
                            Map.of("latitude", 28.250, "longitude", 112.845),
                            Map.of("latitude", 28.250, "longitude", 112.855)
                    )
            );
            var resp = postRaw(workerToken, "/api/v1/farms/1/fences", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        }
    }

    @Nested
    @DisplayName("Owner 牧场创建")
    class OwnerFarmCreation {

        @Test
        @DisplayName("owner 创建新牧场成功")
        void owner_createFarm_success() {
            var body = Map.of(
                    "name", "E2E新建牧场",
                    "latitude", 28.25,
                    "longitude", 112.85,
                    "areaHectares", 100
            );
            var resp = postRaw(ownerToken, "/api/v1/farms", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        }

        @Test
        @DisplayName("owner 创建重复名称牧场失败")
        void owner_createFarm_duplicateName_returnsError() {
            var data = getApi(ownerToken, "/api/v1/farms");
            var items = getItems(data);
            assertThat(items).isNotEmpty();

            @SuppressWarnings("unchecked")
            String existingName = (String) ((Map<String, Object>) items.get(0)).get("name");

            var body = Map.of(
                    "name", existingName,
                    "latitude", 28.25,
                    "longitude", 112.85
            );
            var resp = postRaw(ownerToken, "/api/v1/farms", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        }
    }

    @Nested
    @DisplayName("B2B Admin 牧场查看")
    class B2bAdminFarmView {

        @Test
        @DisplayName("b2b_admin 查看牧场列表成功")
        void b2bAdmin_listFarms_success() {
            var data = getApi(b2bAdminToken, "/api/v1/farms");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items.size()).isGreaterThanOrEqualTo(2);
        }
    }

    @Nested
    @DisplayName("成员管理")
    @TestMethodOrder(OrderAnnotation.class)
    class MemberManagement {

        @Test
        @Order(1)
        @DisplayName("owner 查看牧场成员列表（返回空列表）")
        void owner_listFarmMembers_returnsEmptyList() {
            var data = getApi(ownerToken, "/api/v1/farms/1/members");
            assertThat(data).containsKey("items");
            var items = getItems(data);
            assertThat(items).isEmpty();
        }

        @Test
        @Order(2)
        @DisplayName("owner 添加牧场成员成功")
        void owner_addMember_returnsCreated() {
            // b2b_admin (user 3) is not assigned to farm 1 in seed data
            var body = Map.of("userId", "3", "role", "WORKER");
            var resp = postRaw(ownerToken, "/api/v1/farms/1/members", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
            assertThat(resp.getBody()).isNotNull();
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) resp.getBody().get("data");
            assertThat(data).containsEntry("userId", 3);
            assertThat(data).containsEntry("farmId", 1);
            assertThat(data).containsEntry("role", "WORKER");
        }

        @Test
        @Order(3)
        @DisplayName("owner 重复添加成员返回 409")
        void owner_addMember_duplicate_returns409() {
            var body = Map.of("userId", "3", "role", "WORKER");
            var resp = postRaw(ownerToken, "/api/v1/farms/1/members", body);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
            assertThat(resp.getBody().get("code")).isEqualTo("DUPLICATE_RESOURCE");
        }

        @Test
        @Order(4)
        @Disabled("TODO: 需要本地 Docker 环境调试 — updateStatus 端点在 CI 返回非 200")
        @DisplayName("owner 移除牧场成员成功")
        void owner_removeMember_returnsOk() {
            var addResp = postRaw(ownerToken, "/api/v1/farms/1/members", Map.of("userId", "1", "role", "WORKER"));
            assertThat(addResp.getStatusCode()).isIn(HttpStatus.CREATED, HttpStatus.CONFLICT);
            var resp = deleteRaw(ownerToken, "/api/v1/farms/1/members/1");
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        }
    }
}
