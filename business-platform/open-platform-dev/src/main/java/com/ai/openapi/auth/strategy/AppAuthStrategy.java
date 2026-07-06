package com.ai.openapi.auth.strategy;

import com.ai.openapi.auth.context.RequestContext;
import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.entity.OpenApp;
import com.ai.openapi.mapper.OpenAppMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

@Slf4j
@Component
public class AppAuthStrategy implements AuthStrategy {

    private final OpenAppMapper openAppMapper;
    private final BCryptPasswordEncoder passwordEncoder;

    public AppAuthStrategy(OpenAppMapper openAppMapper, BCryptPasswordEncoder passwordEncoder) {
        this.openAppMapper = openAppMapper;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void authenticate(HttpServletRequest request) {
        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Basic ")) {
            throw new OpenApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(), ErrorCode.UNAUTHORIZED.getCode(),
                    "缺少 Authorization: Basic 头");
        }

        String[] credentials;
        try {
            String decoded = new String(Base64.getDecoder().decode(authorization.substring(6)), StandardCharsets.UTF_8);
            int colonIndex = decoded.indexOf(':');
            if (colonIndex < 0) {
                throw new OpenApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(), ErrorCode.UNAUTHORIZED.getCode(),
                        "Basic Auth 格式错误");
            }
            credentials = new String[]{decoded.substring(0, colonIndex), decoded.substring(colonIndex + 1)};
        } catch (IllegalArgumentException e) {
            throw new OpenApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(), ErrorCode.UNAUTHORIZED.getCode(),
                    "Basic Auth 编码格式错误");
        }

        String appId = credentials[0];
        String appSecret = credentials[1];

        OpenApp app = openAppMapper.selectOne(
                new LambdaQueryWrapper<OpenApp>()
                        .eq(OpenApp::getAppId, appId)
                        .eq(OpenApp::getStatus, "active"));

        if (app == null) {
            throw new OpenApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(), ErrorCode.UNAUTHORIZED.getCode(),
                    "appId 不存在或已禁用");
        }

        if (!passwordEncoder.matches(appSecret, app.getAppSecretHash())) {
            throw new OpenApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(), ErrorCode.UNAUTHORIZED.getCode(),
                    "appSecret 校验失败");
        }

        RequestContext ctx = new RequestContext();
        ctx.setAppId(app.getId());
        ctx.setAppExternalId(app.getAppId());
        ctx.setInternalUserId(app.getInternalUserId());
        ctx.setClientIp(getClientIp(request));
        RequestContext.set(ctx);
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
    }
}
