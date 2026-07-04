package com.ai.openapi.key.service;

import com.ai.openapi.auth.context.RequestContext;
import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.entity.OpenApiKey;
import com.ai.openapi.key.dto.*;
import com.ai.openapi.key.generator.ApiKeyGenerator;
import com.ai.openapi.mapper.OpenApiKeyMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;

@Slf4j
@Service
public class ApiKeyService {

    private static final String CACHE_PREFIX = "open_api:key:";
    private static final long DEFAULT_CACHE_TTL = 300;

    private final OpenApiKeyMapper apiKeyMapper;
    private final ApiKeyGenerator keyGenerator;
    private final BCryptPasswordEncoder passwordEncoder;
    private final RedisTemplate<String, Object> redisTemplate;

    public ApiKeyService(OpenApiKeyMapper apiKeyMapper, ApiKeyGenerator keyGenerator,
                         BCryptPasswordEncoder passwordEncoder, RedisTemplate<String, Object> redisTemplate) {
        this.apiKeyMapper = apiKeyMapper;
        this.keyGenerator = keyGenerator;
        this.passwordEncoder = passwordEncoder;
        this.redisTemplate = redisTemplate;
    }

    public CreateKeyResponse createKey(CreateKeyRequest request) {
        RequestContext ctx = RequestContext.get();

        String keyId = keyGenerator.generateKeyId();
        String apiKeyPlain = keyGenerator.generate();
        String apiKeyHash = passwordEncoder.encode(apiKeyPlain);

        OpenApiKey entity = new OpenApiKey();
        entity.setAppId(ctx.getAppId());
        entity.setKeyId(keyId);
        entity.setApiKeyHash(apiKeyHash);
        entity.setDescription(request.getDescription());
        entity.setScope(request.getScope());
        entity.setStatus("active");
        entity.setInternalUserId(1L);

        if (request.getExpires_in_days() != null) {
            entity.setExpiresAt(OffsetDateTime.now().plusDays(request.getExpires_in_days()));
        }

        apiKeyMapper.insert(entity);

        CreateKeyResponse response = new CreateKeyResponse();
        response.setKey_id(keyId);
        response.setApi_key(apiKeyPlain);
        response.setDescription(request.getDescription());
        response.setScope(request.getScope());
        response.setExpires_at(entity.getExpiresAt());
        response.setCreated_at(entity.getCreatedAt());
        return response;
    }

    public com.ai.openapi.common.response.OpenApiResponse<KeyInfoVO> listKeys(int page, int pageSize) {
        RequestContext ctx = RequestContext.get();

        Page<OpenApiKey> pageQuery = new Page<>(page, pageSize);
        LambdaQueryWrapper<OpenApiKey> wrapper = new LambdaQueryWrapper<OpenApiKey>()
                .eq(OpenApiKey::getAppId, ctx.getAppId())
                .orderByDesc(OpenApiKey::getCreatedAt);

        Page<OpenApiKey> result = apiKeyMapper.selectPage(pageQuery, wrapper);

        var items = result.getRecords().stream().map(key -> {
            KeyInfoVO vo = new KeyInfoVO();
            vo.setKey_id(key.getKeyId());
            vo.setDescription(key.getDescription());
            vo.setScope(key.getScope());
            vo.setStatus(key.getStatus());
            vo.setExpires_at(key.getExpiresAt());
            vo.setLast_used_at(key.getLastUsedAt());
            vo.setCreated_at(key.getCreatedAt());
            return vo;
        }).toList();

        return com.ai.openapi.common.response.OpenApiResponse.of(items, result.getTotal(), page, pageSize);
    }

    public RevokeKeyResponse revokeKey(String keyId) {
        RequestContext ctx = RequestContext.get();

        OpenApiKey key = apiKeyMapper.selectOne(
                new LambdaQueryWrapper<OpenApiKey>()
                        .eq(OpenApiKey::getKeyId, keyId)
                        .eq(OpenApiKey::getAppId, ctx.getAppId()));

        if (key == null) {
            throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(), ErrorCode.NOT_FOUND.getCode(),
                    "key_id 不存在或不属于当前应用");
        }

        key.setStatus("revoked");
        apiKeyMapper.updateById(key);

        evictCache(key);

        RevokeKeyResponse response = new RevokeKeyResponse();
        response.setKey_id(keyId);
        response.setStatus("revoked");
        return response;
    }

    public RotateKeyResponse rotateKey(String keyId) {
        RequestContext ctx = RequestContext.get();

        OpenApiKey key = apiKeyMapper.selectOne(
                new LambdaQueryWrapper<OpenApiKey>()
                        .eq(OpenApiKey::getKeyId, keyId)
                        .eq(OpenApiKey::getAppId, ctx.getAppId())
                        .eq(OpenApiKey::getStatus, "active"));

        if (key == null) {
            throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(), ErrorCode.NOT_FOUND.getCode(),
                    "key_id 不存在、不属于当前应用或已吊销");
        }

        String newApiKeyPlain = keyGenerator.generate();
        String newApiKeyHash = passwordEncoder.encode(newApiKeyPlain);

        evictCache(key);

        key.setApiKeyHash(newApiKeyHash);
        key.setRotatedAt(OffsetDateTime.now());
        apiKeyMapper.updateById(key);

        RotateKeyResponse response = new RotateKeyResponse();
        response.setKey_id(keyId);
        response.setNew_api_key(newApiKeyPlain);
        response.setRotated_at(key.getRotatedAt());
        return response;
    }

    private void evictCache(OpenApiKey key) {
        try {
            var keys = redisTemplate.keys(CACHE_PREFIX + "*");
            if (keys != null && !keys.isEmpty()) {
                redisTemplate.delete(keys);
            }
        } catch (Exception e) {
            log.warn("清除 API Key 缓存失败: {}", e.getMessage());
        }
    }
}
