package com.smartlivestock.docking;

import com.smartlivestock.docking.client.BladeDeviceServiceClient;
import com.smartlivestock.docking.client.DeviceDetailReq;
import com.smartlivestock.docking.client.InternalResponse;
import com.smartlivestock.docking.dto.DeviceDetailResp;
import com.smartlivestock.docking.dto.DevicePageResp;
import com.smartlivestock.docking.dto.DeviceTelemetryResp;
import com.smartlivestock.docking.dto.TelemetryResp;
import com.smartlivestock.docking.oauth.BladeGatewayTokenService;
import com.smartlivestock.docking.service.BladeDeviceService;
import com.smartlivestock.docking.service.BladeServiceException;
import okhttp3.mockwebserver.Dispatcher;
import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import okhttp3.mockwebserver.RecordedRequest;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.io.IOException;
import java.lang.reflect.Field;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

/**
 * End-to-end verification of the Phase C docking (Feign + url mode) against a
 * MockWebServer simulating blade. Test paths and response structures match the
 * real blade API verified on 2026-07-07 against 172.22.4.17.
 */
@SpringBootTest
class BladeDockingVerificationTest {

    static MockWebServer mockBlade;

    @BeforeAll
    static void start() throws IOException {
        mockBlade = new MockWebServer();
        mockBlade.start();
    }

    @AfterAll
    static void stop() throws IOException {
        mockBlade.shutdown();
    }

    @DynamicPropertySource
    static void props(DynamicPropertyRegistry r) {
        String base = "http://localhost:" + mockBlade.getPort();
        r.add("blade.device.base-url", () -> base);
        r.add("blade.license.base-url", () -> base);
        r.add("blade.oauth2.enabled", () -> "true");
        r.add("blade.oauth2.token-uri", () -> base + "/oauth2/token");
        r.add("blade.oauth2.client-id", () -> "test-client");
        r.add("blade.oauth2.client-secret", () -> "test-secret");
        r.add("blade.oauth2.service-user-id", () -> "sl-test-user");
        r.add("blade.oauth2.tenant-id", () -> "000000");
        r.add("blade.service-account.user-id", () -> "sl-test-user");
        r.add("blade.service-account.tenant-id", () -> "000000");
    }

    @Autowired BladeDeviceServiceClient deviceClient;
    @Autowired BladeDeviceService deviceService;
    @Autowired BladeGatewayTokenService gatewayTokenService;

    private final Map<String, Route> routes = new ConcurrentHashMap<>();
    private final Dispatcher dispatcher = new Dispatcher() {
        @Override
        public MockResponse dispatch(RecordedRequest req) {
            String path = req.getPath();
            for (Map.Entry<String, Route> e : routes.entrySet()) {
                if (path.startsWith(e.getKey())) {
                    Route rt = e.getValue();
                    return new MockResponse()
                            .setResponseCode(rt.code())
                            .setHeader("Content-Type", "application/json")
                            .setBody(rt.body());
                }
            }
            return new MockResponse().setResponseCode(404).setBody("no route for " + path);
        }
    };

    @BeforeEach
    void reset() throws Exception {
        // clear token cache so request order is deterministic
        Field f = BladeGatewayTokenService.class.getDeclaredField("cache");
        f.setAccessible(true);
        @SuppressWarnings("unchecked")
        Map<String, ?> cache = (Map<String, ?>) f.get(gatewayTokenService);
        cache.clear();

        // drain MockWebServer request queue to prevent cross-test contamination
        while (mockBlade.takeRequest(0, TimeUnit.MILLISECONDS) != null) {
            // discard stale requests
        }

        routes.clear();
        routes.put("/oauth2/token", token("test-token"));
        mockBlade.setDispatcher(dispatcher);
    }

    private record Route(int code, String body) {}

    private Route token(String t) {
        return new Route(200, "{\"code\":200,\"success\":true,\"data\":{\"accessToken\":\""
                + t + "\",\"tokenType\":\"Bearer\",\"expiresIn\":3600}}");
    }

    private Route ok(String dataJson) {
        return new Route(200, "{\"code\":200,\"success\":true,\"data\":" + dataJson + "}");
    }

    private RecordedRequest takeReq() throws InterruptedException {
        return mockBlade.takeRequest(2, TimeUnit.SECONDS);
    }

    @Test
    @DisplayName("OAuth2 token exchange: /oauth2/token + grant_type=openapi + Basic Auth + Tenant-Id")
    void oauthTokenExchangeWorks() throws Exception {
        routes.put("/feign/v1/device/lifecycle/pageDevices",
                ok("{\"total\":0,\"current\":1,\"pageSize\":1,\"records\":[]}"));
        deviceService.listDevices(1, 1);

        RecordedRequest tokenReq = takeReq();
        assertEquals("/oauth2/token", tokenReq.getPath());
        String tb = tokenReq.getBody().readUtf8();
        assertTrue(tb.contains("grant_type=openapi"), "must use grant_type=openapi");
        assertTrue(tb.contains("userId=sl-test-user"), "must carry userId");
        String auth = tokenReq.getHeader("Authorization");
        assertNotNull(auth);
        assertTrue(auth.startsWith("Basic "), "token endpoint uses Basic auth");
        assertEquals("000000", tokenReq.getHeader("Tenant-Id"));
    }

    @Test
    @DisplayName("Feign request carries 'token' header (blade convention, no Bearer) + Tenant-Id")
    void tokenHeaderInjected() throws Exception {
        routes.put("/feign/v1/device/lifecycle/pageDevices",
                ok("{\"total\":0,\"current\":1,\"pageSize\":1,\"records\":[]}"));
        deviceService.listDevices(1, 1);

        takeReq(); // token request
        RecordedRequest deviceReq = takeReq();
        assertEquals("test-token", deviceReq.getHeader("token"));
        assertNull(deviceReq.getHeader("Authorization"),
                "blade convention is raw 'token' header, not Authorization Bearer");
        assertEquals("000000", deviceReq.getHeader("Tenant-Id"));
    }

    @Test
    @DisplayName("InternalResponse envelope + DevicePageResp parsing")
    void envelopeParsing() {
        routes.put("/feign/v1/device/lifecycle/pageDevices",
                ok("{\"total\":2,\"current\":1,\"pageSize\":2,\"records\":[" +
                   "{\"deviceId\":\"D1\",\"deviceName\":\"dev1\",\"deviceTypeCode\":\"CATTLE_TRACKER\",\"onlineStatus\":1}," +
                   "{\"deviceId\":\"D2\",\"deviceName\":\"dev2\",\"deviceTypeCode\":\"CATTLE_TRACKER\",\"onlineStatus\":0}" +
                   "]}"));
        DevicePageResp page = deviceService.listDevices(1, 2);
        assertEquals(2, page.getTotal());
        assertEquals(2, page.getRecords().size());
        assertEquals("CATTLE_TRACKER", page.getRecords().get(0).getDeviceTypeCode());
    }

    @Test
    @DisplayName("getDeviceWithTelemetry: device detail + telemetry properties")
    void deviceDetailWithTelemetry() throws Exception {
        routes.put("/feign/v1/device/lifecycle/getDeviceDetailWithTelemetry",
                ok("{\"deviceId\":\"D1\",\"deviceName\":\"tracker-001\"," +
                   "\"deviceTypeCode\":\"CATTLE_TRACKER\",\"onlineStatus\":1," +
                   "\"telemetryProperties\":[" +
                   "{\"identifier\":\"battery\",\"name\":\"Battery Level\",\"dataType\":\"int\",\"value\":100}," +
                   "{\"identifier\":\"latitude\",\"name\":\"Latitude\",\"dataType\":\"float\",\"value\":28.24}," +
                   "{\"identifier\":\"longitude\",\"name\":\"Longitude\",\"dataType\":\"float\",\"value\":112.85}" +
                   "]}"));

        DeviceTelemetryResp resp = deviceService.getDeviceWithTelemetry("D1");
        assertEquals("D1", resp.getDeviceId());
        assertEquals("CATTLE_TRACKER", resp.getDeviceTypeCode());
        assertEquals(3, resp.getTelemetryProperties().size());
        assertEquals("battery", resp.getTelemetryProperties().get(0).getIdentifier());
        assertEquals(100, resp.getTelemetryProperties().get(0).getValue());

        takeReq(); // token
        RecordedRequest detailReq = takeReq();
        assertTrue(detailReq.getPath().contains("getDeviceDetailWithTelemetry"));
        assertTrue(detailReq.getPath().contains("deviceId=D1"));
    }

    @Test
    @DisplayName("Telemetry latest: deviceIds + deviceTypeCode -> telemetry data")
    void telemetryLatestQuery() throws Exception {
        routes.put("/feign/v1/device/telemetry/history/latest",
                ok("[{\"deviceId\":null,\"telemetryJson\":{\"lastRow(battery)\":\"100\"," +
                   "\"lastRow(latitude)\":\"28.24\",\"lastRow(longitude)\":\"112.85\"," +
                   "\"lastRow(stepNumber)\":\"42\",\"lastRow(ts)\":\"2026-07-07 14:44:17\"},\"ts\":null}]"));

        List<TelemetryResp> results = deviceService.queryLatestTelemetry(
                List.of("D1", "D2"), "CATTLE_TRACKER");
        assertEquals(1, results.size());
        Map<String, Object> tj = results.get(0).getTelemetryJson();
        assertEquals("100", tj.get("lastRow(battery)"));
        assertEquals("42", tj.get("lastRow(stepNumber)"));

        takeReq(); // token
        RecordedRequest telReq = takeReq();
        assertTrue(telReq.getPath().startsWith("/feign/v1/device/telemetry/history/latest"));
        String body = telReq.getBody().readUtf8();
        assertTrue(body.contains("\"deviceIds\""));
        assertTrue(body.contains("\"deviceTypeCode\":\"CATTLE_TRACKER\""));
    }

    @Test
    @DisplayName("ErrorDecoder: blade HTTP 500 -> BladeServiceException")
    void errorDecoderOn500() {
        routes.put("/feign/v1/device/lifecycle/pageDevices",
                new Route(500, "internal error"));
        BladeServiceException ex = assertThrows(BladeServiceException.class,
                () -> deviceService.listDevices(1, 1));
        assertTrue(ex.getMessage().toLowerCase().contains("unavailable")
                        || ex.getMessage().contains("500"),
                "error decoder should surface a clear message, got: " + ex.getMessage());
    }
}
