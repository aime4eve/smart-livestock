package com.smartlivestock.analytics.domain.port.dto;

import java.time.Instant;

public record ApiKeyInfo(
    Long id, Long tenantId, String keyValue, String keyName, String keyPrefix,
    String status, String scopes, Integer requestsPerMinute, Integer dailyQuota,
    String description, Instant createdAt, Instant lastUsedAt
) {}
