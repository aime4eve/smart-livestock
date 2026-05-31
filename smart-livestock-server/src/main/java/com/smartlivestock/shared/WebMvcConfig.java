package com.smartlivestock.shared;

import com.smartlivestock.platform.web.QuotaInterceptor;
import com.smartlivestock.analytics.interfaces.ApiCallLogInterceptor;
import com.smartlivestock.shared.ratelimit.RateLimitInterceptor;
import com.smartlivestock.shared.scope.FarmScopeInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final FarmScopeInterceptor farmScopeInterceptor;
    private final QuotaInterceptor quotaInterceptor;
    private final RateLimitInterceptor rateLimitInterceptor;
    private final ApiCallLogInterceptor apiCallLogInterceptor;

    public WebMvcConfig(FarmScopeInterceptor farmScopeInterceptor,
                        QuotaInterceptor quotaInterceptor,
                        RateLimitInterceptor rateLimitInterceptor,
                        ApiCallLogInterceptor apiCallLogInterceptor) {
        this.farmScopeInterceptor = farmScopeInterceptor;
        this.quotaInterceptor = quotaInterceptor;
        this.rateLimitInterceptor = rateLimitInterceptor;
        this.apiCallLogInterceptor = apiCallLogInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(rateLimitInterceptor)
                .addPathPatterns("/api/v1/open/**");

        registry.addInterceptor(apiCallLogInterceptor)
                .addPathPatterns("/api/v1/open/**");

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
