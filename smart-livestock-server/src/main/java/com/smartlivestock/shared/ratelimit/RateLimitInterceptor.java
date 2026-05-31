package com.smartlivestock.shared.ratelimit;

import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.shared.security.ApiKeyAuthService;
import com.smartlivestock.shared.security.ApiKeyAuthFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.HexFormat;

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

        ApiKey apiKey = resolveApiKey(request, rawKey);
        int limit = resolveLimit(apiKey);
        String redisKey = "ratelimit:" + sha256(rawKey);

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

    /**
     * Extract API key from X-API-Key header only.
     * Open API uses X-API-Key exclusively; Bearer tokens are handled
     * by JwtAuthenticationFilter in the standard auth chain.
     */
    private String extractApiKey(HttpServletRequest request) {
        String apiKey = request.getHeader("X-API-Key");
        if (apiKey != null && !apiKey.isBlank()) return apiKey.trim();
        return null;
    }

    /**
     * Reuse ApiKey already resolved by ApiKeyAuthFilter (stored as request attribute)
     * to avoid a second DB lookup. Falls back to validateRawKey if not present.
     */
    private ApiKey resolveApiKey(HttpServletRequest request, String rawKey) {
        Object cached = request.getAttribute(ApiKeyAuthFilter.ATTR_API_KEY);
        if (cached instanceof ApiKey key) {
            return key;
        }
        return apiKeyAuthService.validateRawKey(rawKey);
    }

    private int resolveLimit(ApiKey apiKey) {
        Integer rpm = apiKey.getRequestsPerMinute();
        return rpm != null && rpm > 0 ? rpm : 60;
    }

    private static String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            // SHA-256 is guaranteed to exist in JDK
            throw new RuntimeException(e);
        }
    }
}
