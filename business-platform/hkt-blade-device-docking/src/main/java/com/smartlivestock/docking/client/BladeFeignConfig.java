package com.smartlivestock.docking.client;

import com.smartlivestock.docking.oauth.BladeTokenProvider;
import com.smartlivestock.docking.service.BladeServiceException;
import feign.Logger;
import feign.RequestInterceptor;
import feign.Response;
import feign.codec.ErrorDecoder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;

/**
 * Feign configuration shared by all blade clients.
 * Adds: logger level, token header, Tenant-Id header, error decoder.
 *
 * Blade convention (verified): header name is "token" (no Bearer prefix).
 * blade also requires Tenant-Id header on all /feign/v1/* requests.
 */
public class BladeFeignConfig {

    @Bean
    Logger.Level feignLoggerLevel() {
        return Logger.Level.BASIC;
    }

    @Bean
    RequestInterceptor bladeAuthInterceptor(BladeTokenProvider tokenProvider,
                                            @Value("${blade.feign-auth.header-name:token}") String headerName,
                                            @Value("${blade.feign-auth.token-prefix:}") String tokenPrefix,
                                            @Value("${blade.service-account.tenant-id:000000}") String tenantId) {
        return template -> {
            String prefix = tokenPrefix != null ? tokenPrefix : "";
            template.header(headerName, prefix + tokenProvider.getToken());
            template.header("Tenant-Id", tenantId);
        };
    }

    /**
     * Converts HTTP 5xx from blade into BladeServiceException so callers
     * get a clear message instead of raw FeignException.
     */
    @Bean
    ErrorDecoder bladeErrorDecoder() {
        return (methodKey, response) -> {
            if (response.status() >= 500) {
                return new BladeServiceException(
                        "blade service unavailable (HTTP " + response.status() + ") for " + methodKey);
            }
            return new feign.codec.ErrorDecoder.Default().decode(methodKey, response);
        };
    }
}
