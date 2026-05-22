package com.smartlivestock.commerce.application.port;

import com.smartlivestock.commerce.application.dto.QuotaResult;

/**
 * Port for quota checking, implemented by QuotaApplicationService and consumed by platform/web.
 */
public interface QuotaCheckService {
    QuotaResult checkQuota(Long tenantId, String featureKey, int currentUsage);
}
