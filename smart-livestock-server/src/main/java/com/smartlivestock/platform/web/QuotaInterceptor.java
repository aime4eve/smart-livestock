package com.smartlivestock.platform.web;

import com.smartlivestock.commerce.application.dto.QuotaResult;
import com.smartlivestock.commerce.application.port.QuotaCheckService;
import com.smartlivestock.commerce.application.service.UsageResolver;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class QuotaInterceptor implements HandlerInterceptor {

    private final QuotaCheckService quotaCheckService;
    private final Map<String, UsageResolver> resolverMap;

    public QuotaInterceptor(QuotaCheckService quotaCheckService, List<UsageResolver> resolvers) {
        this.quotaCheckService = quotaCheckService;
        this.resolverMap = resolvers.stream()
                .collect(Collectors.toMap(UsageResolver::featureKey, Function.identity()));
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) {
        if (!(handler instanceof HandlerMethod handlerMethod)) {
            return true;
        }

        QuotaCheck annotation = handlerMethod.getMethodAnnotation(QuotaCheck.class);
        if (annotation == null) {
            return true;
        }

        String featureKey = annotation.feature();
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            return true;
        }

        Long farmId = resolveFarmId(request);
        if (farmId == null) {
            return true;
        }

        UsageResolver resolver = resolverMap.get(featureKey);
        int currentUsage = (resolver != null) ? resolver.resolve(tenantId, farmId) : 0;

        QuotaResult result = quotaCheckService.checkQuota(tenantId, featureKey, currentUsage);
        if (!result.isAllowed()) {
            throw new ApiException(ErrorCode.QUOTA_EXCEEDED, result.getReason());
        }

        return true;
    }

    private Long resolveFarmId(HttpServletRequest request) {
        Object resolved = request.getAttribute("resolvedFarmId");
        if (resolved instanceof Long farmId) {
            return farmId;
        }
        return extractFarmIdFromPath(request.getRequestURI());
    }

    private Long extractFarmIdFromPath(String uri) {
        String[] segments = uri.split("/");
        for (int i = 0; i < segments.length - 1; i++) {
            if ("farms".equals(segments[i])) {
                try {
                    return Long.valueOf(segments[i + 1]);
                } catch (NumberFormatException e) {
                    return null;
                }
            }
        }
        return null;
    }
}
