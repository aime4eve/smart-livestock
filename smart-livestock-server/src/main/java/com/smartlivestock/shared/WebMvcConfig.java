package com.smartlivestock.shared;

import com.smartlivestock.platform.web.QuotaInterceptor;
import com.smartlivestock.analytics.interfaces.ApiCallLogInterceptor;
import com.smartlivestock.shared.ratelimit.RateLimitInterceptor;
import com.smartlivestock.shared.scope.FarmScopeInterceptor;
import com.smartlivestock.shared.scope.ScopeInterceptor;
import com.smartlivestock.shared.security.LicenseEnforcementInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final FarmScopeInterceptor farmScopeInterceptor;
    private final QuotaInterceptor quotaInterceptor;
    private final RateLimitInterceptor rateLimitInterceptor;
    private final ApiCallLogInterceptor apiCallLogInterceptor;
    private final ScopeInterceptor scopeInterceptor;
    private final LicenseEnforcementInterceptor licenseEnforcementInterceptor;

    public WebMvcConfig(FarmScopeInterceptor farmScopeInterceptor,
                        QuotaInterceptor quotaInterceptor,
                        RateLimitInterceptor rateLimitInterceptor,
                        ApiCallLogInterceptor apiCallLogInterceptor,
                        ScopeInterceptor scopeInterceptor,
                        LicenseEnforcementInterceptor licenseEnforcementInterceptor) {
        this.farmScopeInterceptor = farmScopeInterceptor;
        this.quotaInterceptor = quotaInterceptor;
        this.rateLimitInterceptor = rateLimitInterceptor;
        this.apiCallLogInterceptor = apiCallLogInterceptor;
        this.scopeInterceptor = scopeInterceptor;
        this.licenseEnforcementInterceptor = licenseEnforcementInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // NIX-184 T5: on-premise license gate runs first (before the quota
        // interceptor) so a blocked tenant never reaches quota evaluation.
        // Exclusions (design §11 enforcement matrix):
        // - /api/v1/auth/**           — login must stay reachable
        // - /api/v1/admin/deployment-license/** — license management survives
        //   PENDING_ACTIVATION / SUSPENDED (that is the recovery path)
        // - /api/v1/admin/tenants/**  — platform operator reach-in
        // - /api/v1/me/**             — DEVIATION from the design §11 list:
        //   the SPA session bootstrap runs on every cold start; blocking it
        //   would brick the frontend before it can surface the license UI.
        registry.addInterceptor(licenseEnforcementInterceptor)
                .addPathPatterns("/api/v1/**")
                .excludePathPatterns("/api/v1/auth/**", "/api/v1/me/**",
                        "/api/v1/admin/deployment-license/**", "/api/v1/admin/tenants/**",
                        // public deployment descriptor: the login screen must
                        // be able to read it even in PENDING_ACTIVATION state
                        "/api/v1/deployment-info");

        registry.addInterceptor(scopeInterceptor)
                .addPathPatterns("/api/v1/open/**");

        registry.addInterceptor(rateLimitInterceptor)
                .addPathPatterns("/api/v1/open/**");

        registry.addInterceptor(apiCallLogInterceptor)
                .addPathPatterns("/api/v1/**");

        registry.addInterceptor(farmScopeInterceptor)
                .addPathPatterns("/api/v1/farms/*/**", "/api/v1/open/farms/*/**",
                        "/api/v1/admin/tenants/*/farms/*/**")
                .excludePathPatterns("/api/v1/auth/**", "/api/v1/me/**",
                        "/api/v1/tenants/**", "/api/v1/device-licenses/**");

        registry.addInterceptor(quotaInterceptor)
                .addPathPatterns("/api/v1/**")
                .excludePathPatterns("/api/v1/auth/**", "/api/v1/open/**");
    }
}
