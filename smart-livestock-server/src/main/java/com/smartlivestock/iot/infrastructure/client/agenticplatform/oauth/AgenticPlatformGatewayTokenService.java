package com.smartlivestock.iot.infrastructure.client.agenticplatform.oauth;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.util.StringUtils;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Exchanges an OAuth2 access_token from agentic-middle-platform auth using grant_type=openapi.
 * Endpoint: POST /oauth2/token (verified against real platform at 172.22.4.17:8108).
 */
@Slf4j
@Service
public class AgenticPlatformGatewayTokenService {

    private final AgenticPlatformOAuth2Properties props;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    private final ConcurrentHashMap<String, CachedToken> cache = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Object> locks = new ConcurrentHashMap<>();

    public AgenticPlatformGatewayTokenService(AgenticPlatformOAuth2Properties props,
                                               @Qualifier("agenticPlatformOAuth2RestTemplate") RestTemplate restTemplate,
                                               ObjectMapper objectMapper) {
        this.props = props;
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void logOauth2Binding() {
        if (isReady()) {
            log.info("agentic-platform.oauth2 ready, token-uri={}", props.getTokenUri());
        } else {
            log.warn("agentic-platform.oauth2 not ready: {}", describeWhyNotReady());
        }
    }

    public boolean isReady() {
        return props.isEnabled()
                && StringUtils.hasText(props.getTokenUri())
                && StringUtils.hasText(props.getClientId())
                && StringUtils.hasText(props.getClientSecret());
    }

    public String describeWhyNotReady() {
        if (!props.isEnabled()) return "agentic-platform.oauth2.enabled is false";
        if (!StringUtils.hasText(props.getTokenUri())) return "agentic-platform.oauth2.token-uri not configured";
        if (!StringUtils.hasText(props.getClientId())) return "agentic-platform.oauth2.client-id not configured";
        if (!StringUtils.hasText(props.getClientSecret())) return "agentic-platform.oauth2.client-secret not configured";
        return "unknown";
    }

    public String getAccessToken(String userId) {
        if (!StringUtils.hasText(userId)) throw new IllegalArgumentException("userId must not be empty");
        CachedToken cached = cache.get(userId);
        if (cached != null && !cached.isExpired()) return cached.accessToken;
        Object lock = locks.computeIfAbsent(userId, k -> new Object());
        synchronized (lock) {
            cached = cache.get(userId);
            if (cached != null && !cached.isExpired()) return cached.accessToken;
            CachedToken fresh = fetchToken(userId);
            cache.put(userId, fresh);
            return fresh.accessToken;
        }
    }

    private CachedToken fetchToken(String userId) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        String raw = props.getClientId() + ":" + props.getClientSecret();
        String basic = Base64.getEncoder().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
        headers.set(HttpHeaders.AUTHORIZATION, "Basic " + basic);
        headers.set("Tenant-Id", props.getTenantId());

        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "openapi");
        form.add("userId", userId);

        HttpEntity<MultiValueMap<String, String>> entity = new HttpEntity<>(form, headers);
        try {
            ResponseEntity<String> response = restTemplate.postForEntity(
                    URI.create(props.getTokenUri()), entity, String.class);
            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                throw new IllegalStateException("token exchange HTTP status abnormal: " + response.getStatusCode());
            }
            OAuthTokenEnvelope envelope = objectMapper.readValue(response.getBody(), OAuthTokenEnvelope.class);
            if (envelope.getCode() != 200 || !envelope.isSuccess()
                    || envelope.getData() == null
                    || !StringUtils.hasText(envelope.getData().getAccessToken())) {
                throw new IllegalStateException("token exchange response invalid: " + envelope.getMsg());
            }
            int expiresIn = envelope.getData().getExpiresIn() != null ? envelope.getData().getExpiresIn() : 3600;
            long skewMs = Math.min(props.getExpirySkewSeconds(), Math.max(0, expiresIn - 1)) * 1000L;
            long expireAt = System.currentTimeMillis() + expiresIn * 1000L - skewMs;
            log.debug("OAuth2 openapi token exchange ok userId={}, expiresIn={}s", userId, expiresIn);
            return new CachedToken(envelope.getData().getAccessToken(), expireAt);
        } catch (HttpStatusCodeException e) {
            log.error("token exchange HTTP failed status={} uri={} userId={}",
                    e.getStatusCode(), props.getTokenUri(), userId, e);
            throw new IllegalStateException("token exchange failed: " + e.getStatusCode(), e);
        } catch (RestClientException e) {
            log.error("token exchange request failed userId={}, uri={}", userId, props.getTokenUri(), e);
            throw new IllegalStateException("token exchange request failed: " + e.getMessage(), e);
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            log.error("token exchange parse failed userId={}", userId, e);
            throw new IllegalStateException("token exchange parse failed: " + e.getMessage(), e);
        }
    }

    private static final class CachedToken {
        private final String accessToken;
        private final long expireAtEpochMs;

        private CachedToken(String accessToken, long expireAtEpochMs) {
            this.accessToken = accessToken;
            this.expireAtEpochMs = expireAtEpochMs;
        }

        private boolean isExpired() {
            return System.currentTimeMillis() >= expireAtEpochMs;
        }
    }
}
