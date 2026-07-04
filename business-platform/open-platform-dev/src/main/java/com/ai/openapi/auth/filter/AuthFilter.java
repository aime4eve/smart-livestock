package com.ai.openapi.auth.filter;

import com.ai.openapi.auth.context.RequestContext;
import com.ai.openapi.auth.strategy.AppAuthStrategy;
import com.ai.openapi.auth.strategy.ApiKeyAuthStrategy;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.response.ErrorResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class AuthFilter extends OncePerRequestFilter {

    private static final String API_KEYS_PREFIX = "/v1/api-keys";

    private final AppAuthStrategy appAuthStrategy;
    private final ApiKeyAuthStrategy apiKeyAuthStrategy;
    private final ObjectMapper objectMapper;

    public AuthFilter(AppAuthStrategy appAuthStrategy, ApiKeyAuthStrategy apiKeyAuthStrategy,
                      ObjectMapper objectMapper) {
        this.appAuthStrategy = appAuthStrategy;
        this.apiKeyAuthStrategy = apiKeyAuthStrategy;
        this.objectMapper = objectMapper;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String path = request.getRequestURI();

        if (shouldSkipAuth(path)) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            if (path.startsWith(API_KEYS_PREFIX)) {
                appAuthStrategy.authenticate(request);
            } else {
                apiKeyAuthStrategy.authenticate(request);
            }
            filterChain.doFilter(request, response);
        } catch (OpenApiException e) {
            response.setStatus(e.getHttpStatus());
            response.setContentType("application/json;charset=UTF-8");
            ErrorResponse error = new ErrorResponse(e.getErrorCode(), e.getMessage(), null);
            response.getWriter().write(objectMapper.writeValueAsString(error));
            return;
        } finally {
            RequestContext.clear();
        }
    }

    private boolean shouldSkipAuth(String path) {
        return path.startsWith("/v3/api-docs")
                || path.startsWith("/swagger-ui")
                || path.equals("/swagger-ui.html")
                || path.equals("/actuator/health")
                || path.startsWith("/debug");
    }
}
