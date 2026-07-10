package com.ai.openapi.auth.strategy;

import com.ai.openapi.auth.context.RequestContext;
import com.ai.openapi.auth.validator.ScopeValidator;
import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.entity.OpenApiKey;
import com.ai.openapi.entity.OpenApp;
import com.ai.openapi.mapper.OpenApiKeyMapper;
import com.ai.openapi.mapper.OpenAppMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.OffsetDateTime;
import java.util.concurrent.TimeUnit;

@Slf4j
@Component
public class ApiKeyAuthStrategy implements AuthStrategy {

    private static final String CACHE_PREFIX = "open_api:key:";
    private static final long DEFAULT_CACHE_TTL = 300;

    private final OpenApiKeyMapper apiKeyMapper;
    private final OpenAppMapper openAppMapper;
    private final RedisTemplate<String, Object> redisTemplate;
    private final BCryptPasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper;
    private final ScopeValidator scopeValidator;

    public ApiKeyAuthStrategy(OpenApiKeyMapper apiKeyMapper,
                             OpenAppMapper openAppMapper,
                             RedisTemplate<String, Object> redisTemplate,
                             BCryptPasswordEncoder passwordEncoder,
                             ObjectMapper objectMapper,
                             ScopeValidator scopeValidator) {
        this.apiKeyMapper = apiKeyMapper;
        this.openAppMapper = openAppMapper;
        this.redisTemplate = redisTemplate;
        this.passwordEncoder = passwordEncoder;
        this.objectMapper = objectMapper;
        this.scopeValidator = scopeValidator;
    }

    @Override
    public void authenticate(HttpServletRequest request) {
        String apiKey = extractApiKey(request);
        if (apiKey == null || apiKey.isEmpty()) {
            throw new OpenApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(), ErrorCode.UNAUTHORIZED.getCode(),
                    "缺少 API Key，请通过 X-API-Key 或 Authorization: Bearer 头传递");
        }

        String cacheKey = CACHE_PREFIX + sha256(apiKey);
        OpenApiKey keyInfo = getFromCache(cacheKey);

        if (keyInfo == null) {
            keyInfo = findByApiKeyHash(apiKey);
            if (keyInfo != null) {
                cacheApiKey(cacheKey, keyInfo);
            }
        }

        if (keyInfo == null) {
            throw new OpenApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(), ErrorCode.UNAUTHORIZED.getCode(),
                    "API Key 无效");
        }

        if (!"active".equals(keyInfo.getStatus())) {
            throw new OpenApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(), ErrorCode.UNAUTHORIZED.getCode(),
                    "API Key 已被吊销");
        }

        if (keyInfo.getExpiresAt() != null && keyInfo.getExpiresAt().isBefore(OffsetDateTime.now())) {
            throw new OpenApiException(ErrorCode.KEY_EXPIRED.getHttpStatus(), ErrorCode.KEY_EXPIRED.getCode(),
                    "API Key 已过期");
        }

        String method = request.getMethod();
        if (!scopeValidator.isAllowed(keyInfo.getScope(), method)) {
            throw new OpenApiException(ErrorCode.FORBIDDEN.getHttpStatus(), ErrorCode.FORBIDDEN.getCode(),
                    "scope '" + keyInfo.getScope() + "' 不允许 " + method + " 操作");
        }

        RequestContext ctx = new RequestContext();
        ctx.setAppId(keyInfo.getAppId());
        ctx.setKeyId(keyInfo.getId());
        ctx.setKeyExternalId(keyInfo.getKeyId());
        ctx.setScope(keyInfo.getScope());
        ctx.setClientIp(getClientIp(request));

        OpenApp app = openAppMapper.selectById(keyInfo.getAppId());
        if (app != null) {
            ctx.setAppExternalId(app.getAppId());
            ctx.setInternalUserId(app.getInternalUserId());
        }

        RequestContext.set(ctx);

        asyncUpdateLastUsedAt(keyInfo);
    }

    private String extractApiKey(HttpServletRequest request) {
        String fromHeader = request.getHeader("X-API-Key");
        if (fromHeader != null && !fromHeader.isEmpty()) {
            return fromHeader;
        }

        String authorization = request.getHeader("Authorization");
        if (authorization != null && authorization.startsWith("Bearer ")) {
            String token = authorization.substring(7);
            if (!token.isEmpty() && !token.startsWith("ey")) {
                return token;
            }
        }

        return null;
    }

    private OpenApiKey getFromCache(String cacheKey) {
        try {
            Object cached = redisTemplate.opsForValue().get(cacheKey);
            if (cached != null) {
                return objectMapper.convertValue(cached, OpenApiKey.class);
            }
        } catch (Exception e) {
            log.warn("读取 API Key 缓存失败: {}", e.getMessage());
        }
        return null;
    }

    private OpenApiKey findByApiKeyHash(String apiKey) {
        LambdaQueryWrapper<OpenApiKey> wrapper = new LambdaQueryWrapper<OpenApiKey>()
                .eq(OpenApiKey::getStatus, "active")
                .isNotNull(OpenApiKey::getApiKeyHash);

        var keys = apiKeyMapper.selectList(wrapper);
        for (OpenApiKey key : keys) {
            if (passwordEncoder.matches(apiKey, key.getApiKeyHash())) {
                return key;
            }
        }

        return null;
    }

    private void cacheApiKey(String cacheKey, OpenApiKey keyInfo) {
        try {
            long ttl = DEFAULT_CACHE_TTL;
            if (keyInfo.getExpiresAt() != null) {
                long secondsUntilExpiry = java.time.Duration.between(
                        OffsetDateTime.now(), keyInfo.getExpiresAt()).getSeconds();
                ttl = Math.max(1, Math.min(secondsUntilExpiry, DEFAULT_CACHE_TTL));
            }
            redisTemplate.opsForValue().set(cacheKey, keyInfo, ttl, TimeUnit.SECONDS);
        } catch (Exception e) {
            log.warn("写入 API Key 缓存失败: {}", e.getMessage());
        }
    }

    private void asyncUpdateLastUsedAt(OpenApiKey keyInfo) {
        try {
            apiKeyMapper.update(null, new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<OpenApiKey>()
                    .eq(OpenApiKey::getId, keyInfo.getId())
                    .set(OpenApiKey::getLastUsedAt, OffsetDateTime.now()));
        } catch (Exception e) {
            log.warn("更新 API Key last_used_at 失败: {}", e.getMessage());
        }
    }

    private String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 不可用", e);
        }
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
    }
}
