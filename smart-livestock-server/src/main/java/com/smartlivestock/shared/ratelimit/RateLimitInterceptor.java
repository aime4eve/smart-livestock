package com.smartlivestock.shared.ratelimit;

import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.shared.security.ApiKeyAuthService;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Duration;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
@Slf4j
public class RateLimitInterceptor implements HandlerInterceptor {

    private static final String HEADER_LIMIT = "X-RateLimit-Limit";
    private static final String HEADER_REMAINING = "X-RateLimit-Remaining";
    private static final String HEADER_RESET = "X-RateLimit-Reset";

    private final RateLimitService rateLimitService;
    private final ApiKeyAuthService apiKeyAuthService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) {
        String rawKey = extractApiKey(request);
        if (rawKey == null || rawKey.isBlank()) {
            return true; // Let ApiKeyAuthFilter handle the 401
        }

        int limit = resolveLimit(rawKey);
        String redisKey = "ratelimit:" + rawKey.hashCode();

        RateLimitService.RateLimitResult result =
                rateLimitService.checkAndRecord(redisKey, limit, Duration.ofSeconds(60));

        response.setHeader(HEADER_LIMIT, String.valueOf(result.limit()));
        response.setHeader(HEADER_REMAINING, String.valueOf(Math.max(0, result.remaining())));
        response.setHeader(HEADER_RESET, String.valueOf(result.resetAtEpochMs() / 1000));

        if (!result.allowed()) {
            response.setStatus(429);
            response.setContentType("application/json;charset=UTF-8");
            try {
                response.getWriter().write(
                        "{\"code\":\"RATE_LIMIT_EXCEEDED\"," +
                        "\"message\":\"请求频率超限，请稍后重试\"," +
                        "\"data\":null}");
            } catch (Exception e) {
                log.error("Failed to write 429 response", e);
            }
            return false;
        }

        return true;
    }

    private String extractApiKey(HttpServletRequest request) {
        String apiKey = request.getHeader("X-API-Key");
        if (apiKey != null && !apiKey.isBlank()) return apiKey.trim();
        String bearer = request.getHeader("Authorization");
        if (bearer != null && bearer.startsWith("Bearer ")) return bearer.substring(7).trim();
        return null;
    }

    private int resolveLimit(String rawKey) {
        try {
            ApiKey apiKey = apiKeyAuthService.validateRawKey(rawKey);
            Integer rpm = apiKey.getRequestsPerMinute();
            return rpm != null && rpm > 0 ? rpm : 60;
        } catch (Exception e) {
            return 60; // Default limit
        }
    }
}
