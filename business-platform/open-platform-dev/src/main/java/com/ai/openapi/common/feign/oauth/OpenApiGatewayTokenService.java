package com.ai.openapi.common.feign.oauth;

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
 * 服务端内部调用统一认证换票（{@code grant_type=openapi}），与对外 API Key 无关。
 */
@Slf4j
@Service
public class OpenApiGatewayTokenService {

    private final OpenApiOAuth2Properties props;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    private final ConcurrentHashMap<String, CachedToken> cache = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Object> locks = new ConcurrentHashMap<>();

    public OpenApiGatewayTokenService(OpenApiOAuth2Properties props,
                                      @Qualifier("openApiOAuth2RestTemplate") RestTemplate restTemplate,
                                      ObjectMapper objectMapper) {
        this.props = props;
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void logOauth2Binding() {
        if (isReady()) {
            log.info("open-api.oauth2 已就绪，Feign 将使用换票 accessToken，token-uri={}", props.getTokenUri());
        } else {
            log.warn("open-api.oauth2 未就绪：{}", describeWhyNotReady());
        }
    }

    public boolean isReady() {
        return props.isEnabled()
                && StringUtils.hasText(props.getTokenUri())
                && StringUtils.hasText(props.getClientId())
                && StringUtils.hasText(props.getClientSecret());
    }

    /** 换票条件未满足时的可读原因，便于排查 Nacos 是否未加载或密钥为空。 */
    public String describeWhyNotReady() {
        if (!props.isEnabled()) {
            return "open-api.oauth2.enabled 为 false（请检查 Nacos hkt-open-api-service.yml 是否加载）";
        }
        if (!StringUtils.hasText(props.getTokenUri())) {
            return "open-api.oauth2.token-uri 未配置";
        }
        if (!StringUtils.hasText(props.getClientId())) {
            return "open-api.oauth2.client-id 未配置";
        }
        if (!StringUtils.hasText(props.getClientSecret())) {
            return "open-api.oauth2.client-secret 未配置或为空";
        }
        return "未知";
    }

    /**
     * 按内部用户 id 换票；带进程内缓存，接近过期时自动刷新。
     */
    public String getAccessToken(String internalUserId) {
        if (!StringUtils.hasText(internalUserId)) {
            throw new IllegalArgumentException("internalUserId 不能为空");
        }
        CachedToken cached = cache.get(internalUserId);
        if (cached != null && !cached.isExpired()) {
            return cached.accessToken;
        }
        Object lock = locks.computeIfAbsent(internalUserId, k -> new Object());
        synchronized (lock) {
            cached = cache.get(internalUserId);
            if (cached != null && !cached.isExpired()) {
                return cached.accessToken;
            }
            CachedToken fresh = fetchToken(internalUserId);
            cache.put(internalUserId, fresh);
            return fresh.accessToken;
        }
    }

    private CachedToken fetchToken(String userId) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        String raw = props.getClientId() + ":" + props.getClientSecret();
        String basic = Base64.getEncoder().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
        headers.set(HttpHeaders.AUTHORIZATION, "Basic " + basic);

        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "openapi");
        form.add("userId", userId);

        HttpEntity<MultiValueMap<String, String>> entity = new HttpEntity<>(form, headers);
        try {
            ResponseEntity<String> response = restTemplate.postForEntity(
                    URI.create(props.getTokenUri()), entity, String.class);
            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                throw new IllegalStateException("换票 HTTP 状态异常: " + response.getStatusCode());
            }
            OAuthTokenEnvelope envelope = objectMapper.readValue(response.getBody(), OAuthTokenEnvelope.class);
            if (envelope.getCode() != 200 || !envelope.isSuccess()
                    || envelope.getData() == null
                    || !StringUtils.hasText(envelope.getData().getAccessToken())) {
                throw new IllegalStateException("换票响应无效: " + envelope.getMsg());
            }
            int expiresIn = envelope.getData().getExpiresIn() != null ? envelope.getData().getExpiresIn() : 3600;
            long skewMs = Math.min(props.getExpirySkewSeconds(), Math.max(0, expiresIn - 1)) * 1000L;
            long expireAt = System.currentTimeMillis() + expiresIn * 1000L - skewMs;
            log.debug("OAuth2 openapi 换票成功 userId={}, expiresIn={}s", userId, expiresIn);
            return new CachedToken(envelope.getData().getAccessToken(), expireAt);
        } catch (HttpStatusCodeException e) {
            String body = e.getResponseBodyAsString(StandardCharsets.UTF_8);
            if (body != null && body.length() > 800) {
                body = body.substring(0, 800) + "...";
            }
            log.error(
                    "换票 HTTP 失败 status={} uri={} userId={} responseBody={} wwwAuthenticate={}",
                    e.getStatusCode(),
                    props.getTokenUri(),
                    userId,
                    body,
                    e.getResponseHeaders().getFirst(HttpHeaders.WWW_AUTHENTICATE));
            if (e.getStatusCode().value() == 401) {
                log.error(
                        "401 通常为：Nacos 里 open-api.oauth2.client-id/client-secret 与中台登记的 OAuth2 客户端不一致；"
                                + "或该客户端未放行 grant_type=openapi；或 token-uri 应走网关域名且需与其它服务一致。请与中台/运维核对。");
            }
            throw new IllegalStateException("换票请求失败: " + e.getStatusCode() + " " + e.getMessage(), e);
        } catch (RestClientException e) {
            log.error("换票请求失败 userId={}, uri={}", userId, props.getTokenUri(), e);
            throw new IllegalStateException("换票请求失败: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("换票解析失败 userId={}", userId, e);
            throw new IllegalStateException("换票解析失败: " + e.getMessage(), e);
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
