package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.infrastructure.persistence.SpringDataUserRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserJpaEntity;
import com.smartlivestock.platform.messaging.push.PushProperties;
import com.smartlivestock.platform.messaging.push.SpringDataUserPushTokenRepository;
import com.smartlivestock.platform.messaging.push.UserPushTokenJpaEntity;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.Set;

/**
 * NIX-430: device push-token registration and the per-user push toggle.
 * Any logged-in USER (JWT); API-key principals are rejected — they identify
 * an api_keys row, not a user, and would collide with users.id (see
 * PasswordChangeRequiredInterceptor's precedent).
 */
@RestController
@RequestMapping("/api/v1/push")
@RequiredArgsConstructor
public class PushTokenController {

    private static final Set<String> PLATFORMS = Set.of("ios", "android");

    private final SpringDataUserPushTokenRepository pushTokenRepository;
    private final SpringDataUserRepository userRepository;
    private final PushProperties pushProperties;
    private final HttpServletRequest request;

    public record RegisterRequest(String platform, String token, String appVersion) {
    }

    public record PreferencesRequest(Boolean enabled) {
    }

    @PostMapping("/register")
    public ApiResponse<Map<String, Object>> register(@RequestBody RegisterRequest body) {
        Long userId = currentUserId();
        if (userId == null) {
            return ApiResponse.error(ErrorCode.AUTH_FORBIDDEN,
                    "推送端点需要用户令牌（API Key 不可用）");
        }
        if (body == null || body.platform() == null
                || !PLATFORMS.contains(body.platform().toLowerCase())
                || body.token() == null || body.token().isBlank()) {
            return ApiResponse.error(ErrorCode.VALIDATION_ERROR,
                    "platform 与 token 必填（platform ∈ ios|android）");
        }
        String platform = body.platform().toLowerCase();
        var existing = pushTokenRepository.findByToken(body.token());
        UserPushTokenJpaEntity row = existing.orElseGet(UserPushTokenJpaEntity::new);
        row.setUserId(userId);
        row.setPlatform(platform);
        row.setToken(body.token());
        // The server stamps its own environment — tokens only match dispatches
        // from the server env the device build actually talks to.
        row.setApnsEnv(pushProperties.getEnvironment());
        row.setAppVersion(body.appVersion());
        pushTokenRepository.save(row);
        return ApiResponse.ok(Map.<String, Object>of("registered", true));
    }

    @PostMapping("/unregister")
    public ApiResponse<Map<String, Object>> unregister(@RequestBody Map<String, String> body) {
        Long userId = currentUserId();
        if (userId == null) {
            return ApiResponse.error(ErrorCode.AUTH_FORBIDDEN,
                    "推送端点需要用户令牌（API Key 不可用）");
        }
        String token = body.get("token");
        if (token == null || token.isBlank()) {
            return ApiResponse.error(com.smartlivestock.shared.common.ErrorCode.VALIDATION_ERROR,
                    "token 必填");
        }
        pushTokenRepository.findByToken(token)
                .filter(row -> userId.equals(row.getUserId()))
                .ifPresent(pushTokenRepository::delete);
        return ApiResponse.ok(Map.<String, Object>of("unregistered", true));
    }

    @PostMapping("/preferences")
    public ApiResponse<Map<String, Object>> updatePreferences(@RequestBody PreferencesRequest body) {
        Long userId = currentUserId();
        if (userId == null) {
            return ApiResponse.error(ErrorCode.AUTH_FORBIDDEN,
                    "推送端点需要用户令牌（API Key 不可用）");
        }
        UserJpaEntity user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            return ApiResponse.error(com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND,
                    "用户不存在");
        }
        boolean enabled = Boolean.TRUE.equals(body != null ? body.enabled() : Boolean.TRUE);
        user.setPushAlertsEnabled(enabled);
        userRepository.save(user);
        return ApiResponse.ok(Map.<String, Object>of("enabled", enabled));
    }

    @GetMapping("/preferences")
    public ApiResponse<Map<String, Object>> preferences() {
        Long userId = currentUserId();
        if (userId == null) {
            return ApiResponse.error(ErrorCode.AUTH_FORBIDDEN,
                    "推送端点需要用户令牌（API Key 不可用）");
        }
        return userRepository.findById(userId)
                .map(u -> ApiResponse.ok(Map.<String, Object>of(
                        "enabled", Boolean.TRUE.equals(u.getPushAlertsEnabled()))))
                .orElseGet(() -> ApiResponse.error(ErrorCode.RESOURCE_NOT_FOUND,
                        "用户不存在"));
    }

    private Long currentUserId() {
        // API-key principals carry an api_keys.id, NOT a user id (they would
        // collide with users.id) — push endpoints are user-only.
        if (request.getAttribute(com.smartlivestock.shared.security.ApiKeyAuthFilter.ATTR_API_KEY) != null) {
            return null;
        }
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof Long userId) {
            return userId;
        }
        return null;
    }
}
