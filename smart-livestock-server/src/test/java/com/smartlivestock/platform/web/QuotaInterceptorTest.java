package com.smartlivestock.platform.web;

import com.smartlivestock.commerce.application.dto.QuotaResult;
import com.smartlivestock.commerce.application.port.QuotaCheckService;
import com.smartlivestock.commerce.application.service.UsageResolver;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.method.HandlerMethod;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class QuotaInterceptorTest {

    @Mock private QuotaCheckService quotaCheckService;
    @Mock private HttpServletRequest request;
    @Mock private HttpServletResponse response;

    private QuotaInterceptor interceptor;

    @BeforeEach
    void setUp() {
        UsageResolver livestockResolver = new UsageResolver() {
            @Override public String featureKey() { return "livestock_management"; }
            @Override public int resolve(Long tenantId, Long farmId) { return 5; }
        };
        interceptor = new QuotaInterceptor(quotaCheckService, List.of(livestockResolver));
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    private HandlerMethod handlerWithAnnotation(String featureKey) {
        HandlerMethod hm = mock(HandlerMethod.class);
        QuotaCheck anno = mock(QuotaCheck.class);
        when(anno.feature()).thenReturn(featureKey);
        when(hm.getMethodAnnotation(QuotaCheck.class)).thenReturn(anno);
        return hm;
    }

    @Nested
    class NonHandlerMethod {

        @Test
        void passesThrough() throws Exception {
            assertThat(interceptor.preHandle(request, response, new Object())).isTrue();
            verifyNoInteractions(quotaCheckService);
        }
    }

    @Nested
    class NoQuotaCheckAnnotation {

        @Test
        void passesThrough() throws Exception {
            HandlerMethod hm = mock(HandlerMethod.class);
            when(hm.getMethodAnnotation(QuotaCheck.class)).thenReturn(null);

            assertThat(interceptor.preHandle(request, response, hm)).isTrue();
            verifyNoInteractions(quotaCheckService);
        }
    }

    @Nested
    class WithAnnotation {

        @Test
        void noTenantId_passesThrough() throws Exception {
            TenantContext.clear();
            HandlerMethod hm = handlerWithAnnotation("livestock_management");

            assertThat(interceptor.preHandle(request, response, hm)).isTrue();
            verifyNoInteractions(quotaCheckService);
        }

        @Test
        void noFarmId_passesThrough() throws Exception {
            TenantContext.setCurrentTenant(1L);
            when(request.getAttribute("resolvedFarmId")).thenReturn(null);
            when(request.getRequestURI()).thenReturn("/api/v1/livestock");
            HandlerMethod hm = handlerWithAnnotation("livestock_management");

            assertThat(interceptor.preHandle(request, response, hm)).isTrue();
            verifyNoInteractions(quotaCheckService);
        }

        @Test
        void quotaAllowed_passesThrough() throws Exception {
            TenantContext.setCurrentTenant(1L);
            when(request.getAttribute("resolvedFarmId")).thenReturn(10L);
            when(quotaCheckService.checkQuota(1L, "livestock_management", 5))
                    .thenReturn(QuotaResult.allowed());

            assertThat(interceptor.preHandle(request, response, handlerWithAnnotation("livestock_management"))).isTrue();
        }

        @Test
        void quotaAllowedWithRetention_passesThrough() throws Exception {
            TenantContext.setCurrentTenant(1L);
            when(request.getAttribute("resolvedFarmId")).thenReturn(10L);
            when(quotaCheckService.checkQuota(1L, "livestock_management", 5))
                    .thenReturn(QuotaResult.allowedWithRetention(30));

            assertThat(interceptor.preHandle(request, response, handlerWithAnnotation("livestock_management"))).isTrue();
        }

        @Test
        void quotaDenied_throwsApiException() throws Exception {
            TenantContext.setCurrentTenant(1L);
            when(request.getAttribute("resolvedFarmId")).thenReturn(10L);
            when(quotaCheckService.checkQuota(1L, "livestock_management", 5))
                    .thenReturn(QuotaResult.denied("已达到上限"));

            assertThatThrownBy(() -> interceptor.preHandle(request, response, handlerWithAnnotation("livestock_management")))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                            .isEqualTo(ErrorCode.QUOTA_EXCEEDED));
        }

        @Test
        void farmIdFromPath_whenAttributeMissing() throws Exception {
            TenantContext.setCurrentTenant(1L);
            when(request.getAttribute("resolvedFarmId")).thenReturn(null);
            when(request.getRequestURI()).thenReturn("/api/v1/farms/20/livestock");
            when(quotaCheckService.checkQuota(1L, "livestock_management", 5))
                    .thenReturn(QuotaResult.allowed());

            assertThat(interceptor.preHandle(request, response, handlerWithAnnotation("livestock_management"))).isTrue();
            verify(quotaCheckService).checkQuota(1L, "livestock_management", 5);
        }

        @Test
        void unknownFeatureKey_usesZeroUsage() throws Exception {
            TenantContext.setCurrentTenant(1L);
            when(request.getAttribute("resolvedFarmId")).thenReturn(10L);
            when(quotaCheckService.checkQuota(1L, "unknown_feature", 0))
                    .thenReturn(QuotaResult.allowed());

            assertThat(interceptor.preHandle(request, response, handlerWithAnnotation("unknown_feature"))).isTrue();
            verify(quotaCheckService).checkQuota(1L, "unknown_feature", 0);
        }
    }
}
