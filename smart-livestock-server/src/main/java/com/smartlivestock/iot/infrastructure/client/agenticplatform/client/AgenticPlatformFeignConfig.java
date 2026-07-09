package com.smartlivestock.iot.infrastructure.client.agenticplatform.client;

import com.smartlivestock.iot.infrastructure.client.agenticplatform.oauth.AgenticPlatformTokenProvider;
import feign.Logger;
import feign.RequestInterceptor;
import feign.codec.ErrorDecoder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;

/**
 * Feign configuration shared by all agentic-middle-platform clients.
 * Adds: logger level, token header, Tenant-Id header, error decoder.
 *
 * Platform convention (verified): header name is "token" (no Bearer prefix).
 * Platform also requires Tenant-Id header on all /feign/v1/* requests.
 */
public class AgenticPlatformFeignConfig {

    @Bean
    Logger.Level feignLoggerLevel() {
        return Logger.Level.BASIC;
    }

    @Bean
    RequestInterceptor agenticPlatformAuthInterceptor(AgenticPlatformTokenProvider tokenProvider,
                                            @Value("${agentic-platform.feign-auth.header-name:token}") String headerName,
                                            @Value("${agentic-platform.feign-auth.token-prefix:}") String tokenPrefix,
                                            @Value("${agentic-platform.service-account.tenant-id:000000}") String tenantId) {
        return template -> {
            String prefix = tokenPrefix != null ? tokenPrefix : "";
            template.header(headerName, prefix + tokenProvider.getToken());
            template.header("Tenant-Id", tenantId);
        };
    }

    @Bean
    ErrorDecoder agenticPlatformErrorDecoder() {
        return (methodKey, response) -> {
            if (response.status() >= 500) {
                return new AgenticPlatformServiceException(
                        "agentic-middle-platform service unavailable (HTTP " + response.status() + ") for " + methodKey);
            }
            return new ErrorDecoder.Default().decode(methodKey, response);
        };
    }
}
