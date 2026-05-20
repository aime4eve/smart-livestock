package com.smartlivestock.commerce.application.port;

import com.smartlivestock.commerce.application.dto.QuotaResult;

public interface QuotaCheckService {
    QuotaResult checkQuota(Long tenantId, String featureKey, int currentUsage);
}
