package com.smartlivestock.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Task 0 (NIX-20): Regression baseline for the existing <em>static</em>
 * GPS-quality check endpoints (PLATFORM_ADMIN, {@code /api/v1/admin/gps-quality}).
 *
 * <p>This suite pins the current behaviour of the legacy single-table model
 * (rtk_reference_points + rtk_calibration_sessions + gps_logs) so the upcoming
 * "unified GPS table" migration can be validated against it. It does not modify
 * any production code — every assertion targets the live API as it behaves today.
 *
 * <h3>Seed data (already present via Flyway)</h3>
 * <ul>
 *   <li>RTK point id=1 — 宿舍楼顶 1号点 (28.2453909, 112.8507819); ids 1-33 seeded</li>
 *   <li>Trackers DEV-GPS-001..050 (device ids 1-50, type TRACKER)</li>
 *   <li>No calibration sessions are seeded — the table starts empty</li>
 * </ul>
 *
 * <h3>Isolation strategy</h3>
 * All {@code @Test} methods share one Testcontainers database (one Spring context).
 * Tests are kept independent of execution order by:
 * <ul>
 *   <li>using a dedicated device id per scenario (the "one IN_PROGRESS per device"
 *       DB constraint and the per-device time-window overlap rule are respected);</li>
 *   <li>using dedicated RTK points (id=2 for filtering, id=3 for comparison) that no
 *       other scenario touches, so list/count assertions stay deterministic;</li>
 *   <li>backfill (COMPLETED) windows occupy only a bounded slice of a device's
 *       timeline; live sessions that would "poison" a device live on devices that
 *       are never reused by another scenario.</li>
 * </ul>
 */
class GpsQualityJourneyTest extends AbstractJourneyTest {

    private static final String BASE = "/api/v1/admin/gps-quality";

    // Dedicated RTK points per scenario (all exist in seed; none share a scenario).
    private static final long RTK_POINT_1 = 1L; // shared read/create surface
    private static final long RTK_POINT_2 = 2L; // filtering scenario (isolated)
    private static final long RTK_POINT_3 = 3L; // comparison scenario (isolated)

    // Past time anchors (must precede "now" to satisfy backfill validation).
    private static final String T0900 = "2026-07-10T09:00:00Z";
    private static final String T0930 = "2026-07-10T09:30:00Z";

    // ------------------------------------------------------------------
    // Small helpers not present in AbstractJourneyTest
    // ------------------------------------------------------------------

    /** PATCH with auth; asserts 200 and returns the {@code data} payload. */
    @SuppressWarnings("unchecked")
    private Map<String, Object> patchApi(String token, String path, Object body) {
        HttpHeaders headers = authHeaders(token);
        ResponseEntity<Map> resp = restTemplate.exchange(
                path, HttpMethod.PATCH, new HttpEntity<>(body, headers), Map.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        return (Map<String, Object>) resp.getBody().get("data");
    }

    /** Extract {@code data} from a list-valued response (plain List, not a Page). */
    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> dataList(ResponseEntity<Map> resp) {
        assertOk(resp);
        return (List<Map<String, Object>>) resp.getBody().get("data");
    }

    /** Extract the item list from a Spring Data {@code Page} payload. */
    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> pageContent(Map<String, Object> pageData) {
        Object content = pageData.get("content");
        assertThat(content).isInstanceOf(List.class);
        return (List<Map<String, Object>>) content;
    }

    private Map<String, Object> backfillBody(long rtkPointId, long deviceId) {
        Map<String, Object> body = new HashMap<>();
        body.put("rtkPointId", rtkPointId);
        body.put("deviceId", deviceId);
        body.put("startedAt", T0900);
        body.put("endedAt", T0930);
        return body;
    }

    /** Live session body (no endedAt => IN_PROGRESS on create). */
    private Map<String, Object> liveBody(long rtkPointId, long deviceId, String startedAt) {
        Map<String, Object> body = new HashMap<>();
        body.put("rtkPointId", rtkPointId);
        body.put("deviceId", deviceId);
        body.put("startedAt", startedAt);
        return body;
    }

    private long asLong(Map<String, Object> data, String key) {
        return ((Number) data.get(key)).longValue();
    }

    // ------------------------------------------------------------------
    // 1. RTK reference points + device list
    // ------------------------------------------------------------------

    @Test
    @DisplayName("1. RTK 参考点列表可读且含 seed 点；新建点返回正确字段；设备列表可读")
    void rtkPointAndDeviceManagement() {
        // --- devices list ---
        List<Map<String, Object>> devices = dataList(getRaw(platformAdminToken, BASE + "/devices"));
        assertThat(devices).isNotEmpty();
        assertThat(devices).anyMatch(d -> "DEV-GPS-001".equals(d.get("deviceCode")));

        // --- RTK points list ---
        List<Map<String, Object>> points = dataList(getRaw(platformAdminToken, BASE + "/rtk-points"));
        assertThat(points.size()).isGreaterThanOrEqualTo(33);
        assertThat(points).anyMatch(p ->
                asLong(p, "id") == 1L && "宿舍楼顶".equals(p.get("locationName")));

        // --- create a new RTK point ---
        Map<String, Object> body = new HashMap<>();
        body.put("locationName", "测试标定区");
        body.put("pointLabel", "QA-1");
        body.put("latitude", 28.2450000);
        body.put("longitude", 112.8500000);
        Map<String, Object> created = postApi(platformAdminToken, BASE + "/rtk-points", body);

        assertThat(created.get("id")).isNotNull();
        assertThat(created.get("locationName")).isEqualTo("测试标定区");
        assertThat(created.get("pointLabel")).isEqualTo("QA-1");
        assertThat(created.get("latitude")).isNotNull();
        assertThat(created.get("longitude")).isNotNull();
    }

    // ------------------------------------------------------------------
    // 2. Create a live static session -> IN_PROGRESS
    // ------------------------------------------------------------------

    @Test
    @DisplayName("2. 创建静态标定会话（live）返回 id / status=IN_PROGRESS")
    void createLiveSession() {
        Map<String, Object> created = postApi(platformAdminToken, BASE + "/sessions",
                liveBody(RTK_POINT_1, 1L, T0900));

        assertThat(created.get("id")).isNotNull();
        assertThat(created.get("status")).isEqualTo("IN_PROGRESS");
        assertThat(created.get("startedAt")).isNotNull();
        assertThat(asLong(created, "rtkPointId")).isEqualTo(RTK_POINT_1);
        assertThat(asLong(created, "deviceId")).isEqualTo(1L);
        assertThat(created.get("deviceCode")).isEqualTo("DEV-GPS-001");
        // live session has no end time yet
        assertThat(created.get("endedAt")).isNull();
    }

    // ------------------------------------------------------------------
    // 3. Session state machine: end -> COMPLETED, cancel -> CANCELED
    // ------------------------------------------------------------------

    @Test
    @DisplayName("3. 会话状态机：end→COMPLETED(endedAt 非空)；cancel→CANCELED")
    void sessionStateMachine() {
        // --- end: IN_PROGRESS -> COMPLETED (device 2) ---
        Map<String, Object> live = postApi(platformAdminToken, BASE + "/sessions",
                liveBody(RTK_POINT_1, 2L, T0900));
        assertThat(live.get("status")).isEqualTo("IN_PROGRESS");

        Map<String, Object> ended = patchApi(platformAdminToken,
                BASE + "/sessions/" + asLong(live, "id") + "/end", null);
        assertThat(ended.get("status")).isEqualTo("COMPLETED");
        assertThat(ended.get("endedAt")).as("endedAt must be set after end").isNotNull();

        // --- cancel: IN_PROGRESS -> CANCELED (device 3) ---
        Map<String, Object> another = postApi(platformAdminToken, BASE + "/sessions",
                liveBody(RTK_POINT_1, 3L, T0900));
        assertThat(another.get("status")).isEqualTo("IN_PROGRESS");

        Map<String, Object> canceled = deleteApi(platformAdminToken,
                BASE + "/sessions/" + asLong(another, "id"));
        assertThat(canceled.get("status")).isEqualTo("CANCELED");
    }

    // ------------------------------------------------------------------
    // 4. Session list filtering by rtkPointId / status
    // ------------------------------------------------------------------

    @Test
    @DisplayName("4. 会话列表按 rtkPointId / status 过滤返回正确子集")
    void sessionListFiltering() {
        // seed two sessions of distinct statuses on the isolated RTK point 2
        postApi(platformAdminToken, BASE + "/sessions", backfillBody(RTK_POINT_2, 4L)); // COMPLETED
        Map<String, Object> live = postApi(platformAdminToken, BASE + "/sessions",
                liveBody(RTK_POINT_2, 5L, T0900));                                      // IN_PROGRESS
        deleteApi(platformAdminToken, BASE + "/sessions/" + asLong(live, "id"));        // -> CANCELED

        // filter by status=COMPLETED on point 2
        Map<String, Object> completedPage = getApi(platformAdminToken,
                BASE + "/sessions?rtkPointId=" + RTK_POINT_2 + "&status=COMPLETED");
        List<Map<String, Object>> completed = pageContent(completedPage);
        assertThat(completed).isNotEmpty();
        assertThat(completed).allMatch(s -> "COMPLETED".equals(s.get("status")));

        // filter by status=CANCELED on point 2
        Map<String, Object> canceledPage = getApi(platformAdminToken,
                BASE + "/sessions?rtkPointId=" + RTK_POINT_2 + "&status=CANCELED");
        List<Map<String, Object>> canceled = pageContent(canceledPage);
        assertThat(canceled).isNotEmpty();
        assertThat(canceled).allMatch(s -> "CANCELED".equals(s.get("status")));

        // unfiltered on point 2 returns at least both
        Map<String, Object> allPage = getApi(platformAdminToken,
                BASE + "/sessions?rtkPointId=" + RTK_POINT_2);
        assertThat(pageContent(allPage).size()).isGreaterThanOrEqualTo(2);
    }

    // ------------------------------------------------------------------
    // 5. Only one IN_PROGRESS session per device
    // ------------------------------------------------------------------

    @Test
    @DisplayName("5. 同一设备已有 IN_PROGRESS 时再创建 live 会话返回 409 冲突")
    void oneInProgressPerDeviceConflict() {
        // first live session -> IN_PROGRESS (device 6)
        Map<String, Object> first = postApi(platformAdminToken, BASE + "/sessions",
                liveBody(RTK_POINT_1, 6L, T0900));
        assertThat(first.get("status")).isEqualTo("IN_PROGRESS");

        // second live session on the same device -> must be rejected (non-200)
        ResponseEntity<Map> conflict = postRaw(platformAdminToken, BASE + "/sessions",
                liveBody(RTK_POINT_1, 6L, "2026-07-10T10:00:00Z"));
        assertThat(conflict.getStatusCode()).isNotEqualTo(HttpStatus.OK);
        assertThat(conflict.getStatusCode().is2xxSuccessful()).isFalse();
        assertError(conflict, HttpStatus.CONFLICT, "STATE_CONFLICT");

        // cleanup so device 6 is not left IN_PROGRESS
        deleteApi(platformAdminToken, BASE + "/sessions/" + asLong(first, "id"));
    }

    // ------------------------------------------------------------------
    // 6. Static quality report for a COMPLETED session
    // ------------------------------------------------------------------

    @Test
    @DisplayName("6. 对 COMPLETED 会话生成静态报告，stats 对象字段存在且类型合理")
    void staticReport() {
        Map<String, Object> session = postApi(platformAdminToken, BASE + "/sessions",
                backfillBody(RTK_POINT_1, 7L));
        assertThat(session.get("status")).isEqualTo("COMPLETED");

        Map<String, Object> report = getApi(platformAdminToken,
                BASE + "/sessions/" + asLong(session, "id") + "/report");

        assertThat(asLong(report, "sessionId")).isEqualTo(asLong(session, "id"));
        assertThat(asLong(report, "rtkPointId")).isEqualTo(RTK_POINT_1);
        assertThat(report.get("locationName")).isEqualTo("宿舍楼顶");
        assertThat(report.get("rtkLatitude")).isNotNull();
        assertThat(report.get("rtkLongitude")).isNotNull();
        assertThat(report.get("grade")).as("top-level grade is present").isNotNull();

        // stats object: field existence + type reasonableness (no exact values)
        Map<String, Object> stats = (Map<String, Object>) report.get("stats");
        assertThat(stats).isNotNull();
        assertThat(((Number) stats.get("totalPoints")).intValue()).isGreaterThanOrEqualTo(0);
        assertThat(((Number) stats.get("effectivePoints")).intValue()).isGreaterThanOrEqualTo(0);
        assertThat(((Number) stats.get("p95")).doubleValue()).isGreaterThanOrEqualTo(0.0);
        assertThat(stats.get("grade")).as("stats grade is present").isNotNull();
    }

    // ------------------------------------------------------------------
    // 7. Trajectory scatter (may be empty but well-formed)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("7. 轨迹端点返回散点列表（可为空但结构正确）")
    void trajectoryScatter() {
        Map<String, Object> session = postApi(platformAdminToken, BASE + "/sessions",
                backfillBody(RTK_POINT_1, 8L));

        List<Map<String, Object>> scatter = dataList(getRaw(platformAdminToken,
                BASE + "/sessions/" + asLong(session, "id") + "/trajectory"));

        assertThat(scatter).isNotNull();
        for (Map<String, Object> point : scatter) {
            assertThat(point.get("latitude")).isNotNull();
            assertThat(point.get("longitude")).isNotNull();
            assertThat(point).containsKey("error");
            assertThat(point).containsKey("recordedAt");
            assertThat(point).containsKey("suspect");
        }
    }

    // ------------------------------------------------------------------
    // 8. Multi-device comparison for a single RTK point
    // ------------------------------------------------------------------

    @Test
    @DisplayName("8. 多设备对比返回 entries 列表，结构正确")
    void multiDeviceComparison() {
        // two COMPLETED sessions from different devices on the isolated point 3
        postApi(platformAdminToken, BASE + "/sessions", backfillBody(RTK_POINT_3, 9L));
        postApi(platformAdminToken, BASE + "/sessions", backfillBody(RTK_POINT_3, 10L));

        Map<String, Object> comparison = getApi(platformAdminToken,
                BASE + "/comparison?rtkPointId=" + RTK_POINT_3);

        assertThat(asLong(comparison, "rtkPointId")).isEqualTo(RTK_POINT_3);
        assertThat(comparison.get("locationName")).isNotNull();
        assertThat(comparison.get("label")).isNotNull();

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> devices = (List<Map<String, Object>>) comparison.get("devices");
        assertThat(devices).isNotNull();
        assertThat(devices.size()).as("comparison includes every COMPLETED session").isGreaterThanOrEqualTo(2);

        Map<String, Object> first = devices.get(0);
        assertThat(first.get("sessionId")).isNotNull();
        assertThat(first.get("deviceId")).isNotNull();
        assertThat(first.get("deviceCode")).isNotNull();
        assertThat(first.get("grade")).isNotNull();
        assertThat(first).containsKey("p95");
        assertThat(first).containsKey("meanError");
        assertThat(first).containsKey("effectivePoints");
    }
}
