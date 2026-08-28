package com.smartlivestock.iot.infrastructure.client.thingsboard;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestOperations;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriUtils;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Locale;

/**
 * ThingsBoard REST client (NIX-179 Phase 1).
 * <p>
 * TB conventions (verified on 172.22.3.105, TB 3.8.0):
 * - login: POST /api/auth/login {username,password} → {token, refreshToken}
 * - every call carries "X-Authorization: Bearer <token>" (NOT "Authorization")
 * - 401 → re-login once and replay
 */
@Component
@Slf4j
public class TbClient {

    private static final String TB_KEYS = "result,dataHex,rssi,snr,downLinkGateway";

    private final TbProperties properties;
    private final ObjectMapper objectMapper;
    private final RestOperations rest;

    @Autowired
    public TbClient(TbProperties properties, ObjectMapper objectMapper) {
        this(properties, objectMapper, new RestTemplate());
    }

    TbClient(TbProperties properties, ObjectMapper objectMapper, RestOperations rest) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.rest = rest;
    }

    private final Map<String, CachedToken> tokenCache = new ConcurrentHashMap<>();

    public JsonNode fetchTimeseries(String tbDeviceId, long startTs, long endTs, int limit) {
        String path = "/api/plugins/telemetry/DEVICE/" + tbDeviceId + "/values/timeseries"
                + "?keys=" + TB_KEYS
                + "&startTs=" + startTs + "&endTs=" + endTs
                + "&orderBy=ASC&limit=" + limit;
        return exchangeForJson(path, HttpMethod.GET, null);
    }

    /**
     * Resolve a DevEUI to its TB device id using the three-variant exact match
     * (as-is → upper → lower, parking NIX-80 D11). TB textSearch is fuzzy, so
     * results are filtered to exact name equality per variant. Multiple distinct
     * matches mean ambiguous data (e.g. case twins with different payloads) and
     * must not be silently auto-bound.
     */
    public String resolveDeviceId(String eui) {
        LinkedHashSet<String> matches = new LinkedHashSet<>();
        for (String variant : variantsOf(eui)) {
            String path = "/api/tenant/devices?pageSize=100&page=0&textSearch="
                    + UriUtils.encodeQueryParam(variant, StandardCharsets.UTF_8);
            JsonNode page = exchangeForJson(path, HttpMethod.GET, null);
            for (JsonNode device : page.path("data")) {
                if (variant.equals(device.path("name").asText())) {
                    matches.add(device.path("id").path("id").asText());
                }
            }
        }
        if (matches.isEmpty()) {
            throw new IllegalStateException("TB device not found for EUI " + eui);
        }
        if (matches.size() > 1) {
            throw new IllegalStateException("Ambiguous TB devices for EUI " + eui + ": " + matches);
        }
        return matches.iterator().next();
    }

    static List<String> variantsOf(String eui) {
        List<String> variants = new ArrayList<>();
        if (eui != null && !eui.isBlank()) {
            variants.add(eui);
            String upper = eui.toUpperCase(Locale.ROOT);
            String lower = eui.toLowerCase(Locale.ROOT);
            if (!variants.contains(upper)) variants.add(upper);
            if (!variants.contains(lower)) variants.add(lower);
        }
        return variants;
    }

    private JsonNode exchangeForJson(String path, HttpMethod method, JsonNode body) {
        try {
            return doExchange(path, method, body, false);
        } catch (TbUnauthorizedException e) {
            log.info("[TB] 401 received, re-login and replay once: {}", path);
            return doExchange(path, method, body, true);
        }
    }

    private JsonNode doExchange(String path, HttpMethod method, JsonNode body, boolean forceRelogin) {
        String token = getToken(forceRelogin);
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("X-Authorization", "Bearer " + token);
            if (body != null) headers.setContentType(MediaType.APPLICATION_JSON);
            ResponseEntity<String> resp = rest.exchange(
                    properties.getBaseUrl() + path, method, new HttpEntity<>(body, headers), String.class);
            return objectMapper.readTree(resp.getBody() == null ? "{}" : resp.getBody());
        } catch (HttpStatusCodeException e) {
            if (e.getStatusCode().value() == 401) {
                throw new TbUnauthorizedException(e);
            }
            throw new IllegalStateException("TB call failed: " + path + " -> " + e.getStatusCode(), e);
        } catch (Exception e) {
            if (e instanceof TbUnauthorizedException) throw (TbUnauthorizedException) e;
            throw new IllegalStateException("TB call failed: " + path, e);
        }
    }

    private synchronized String getToken(boolean forceRelogin) {
        String key = properties.getUsername();
        CachedToken cached = tokenCache.get(key);
        if (!forceRelogin && cached != null && Instant.now().isBefore(cached.expiresAt)) {
            return cached.token;
        }
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            Map<String, String> payload = Map.of("username", key, "password", properties.getPassword());
            ResponseEntity<String> resp = rest.postForEntity(
                    properties.getBaseUrl() + "/api/auth/login",
                    new HttpEntity<>(objectMapper.writeValueAsString(payload), headers),
                    String.class);
            JsonNode node = objectMapper.readTree(resp.getBody());
            // TB returns token + refreshToken with ~1h TTL; refresh at 50 min.
            String token = node.path("token").asText();
            if (token.isBlank()) {
                throw new IllegalStateException("TB login returned no token");
            }
            tokenCache.put(key, new CachedToken(token, Instant.now().plusSeconds(3000)));
            log.info("[TB] login ok for {}", key);
            return token;
        } catch (TbUnauthorizedException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("TB login failed for " + key, e);
        }
    }

    private record CachedToken(String token, Instant expiresAt) {}

    private static class TbUnauthorizedException extends RuntimeException {
        TbUnauthorizedException(Throwable cause) {
            super("TB unauthorized", cause);
        }
    }
}
