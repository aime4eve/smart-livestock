package com.smartlivestock.shared;

import com.smartlivestock.shared.scope.FarmScopeInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final FarmScopeInterceptor farmScopeInterceptor;

    public WebMvcConfig(FarmScopeInterceptor farmScopeInterceptor) {
        this.farmScopeInterceptor = farmScopeInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(farmScopeInterceptor)
                .addPathPatterns("/api/v1/farms/*/**", "/api/v1/open/farms/*/**",
                        "/api/v1/admin/tenants/*/farms/*/**")
                .excludePathPatterns("/api/v1/auth/**", "/api/v1/me/**",
                        "/api/v1/tenants/**", "/api/v1/device-licenses/**");
    }
}
