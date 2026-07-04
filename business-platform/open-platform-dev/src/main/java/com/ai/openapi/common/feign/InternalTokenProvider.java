package com.ai.openapi.common.feign;

import com.ai.openapi.auth.context.RequestContext;
import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.feign.oauth.OpenApiGatewayTokenService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * Feign 访问中台时的 Bearer 来源：在启用 {@code open-api.oauth2} 时，按当前请求
 * {@link com.ai.openapi.auth.context.RequestContext#getInternalUserId()} 向统一网关换票；
 * 换票逻辑对 API 调用方不可见。
 */
@Slf4j
@Component
public class InternalTokenProvider {

    private final OpenApiGatewayTokenService gatewayTokenService;

    @Value("${open-api.internal-token:}")
    private String staticToken;

    public InternalTokenProvider(OpenApiGatewayTokenService gatewayTokenService) {
        this.gatewayTokenService = gatewayTokenService;
    }

    /**
     * 供 {@link FeignAuthInterceptor} 使用。
     * <p>
     * 中台若<strong>无</strong>固定内部 token：请启用 {@code open-api.oauth2}，仅用换票得到的 Bearer；
     * 未启用 OAuth 且无静态 token 时会直接失败，避免误带无效占位串访问中台。
     */
    public String getToken() {
        RequestContext ctx = RequestContext.get();
        String userId = ctx != null ? ctx.getInternalUserId() : null;

        if (gatewayTokenService.isReady()) {
            if (!StringUtils.hasText(userId)) {
                throw new OpenApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(), ErrorCode.INTERNAL_ERROR.getCode(),
                        "已启用 open-api.oauth2，但当前应用缺少内部用户绑定，无法换取访问中台的令牌（请检查 open_app.internal_user_id）");
            }
            try {
                return gatewayTokenService.getAccessToken(userId);
            } catch (Exception e) {
                log.error("网关 OAuth2 换票失败 userId={}", userId, e);
                throw new OpenApiException(
                        ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                        ErrorCode.UPSTREAM_ERROR.getCode(),
                        "访问中台失败：换取访问令牌被认证服务拒绝或服务异常。"
                                + "请管理员核对 Nacos 中 open-api.oauth2 的 client-id、client-secret 是否与网关 OAuth2 客户端一致（网关若返回「用户名或密码错误」即属此类）；"
                                + "与调用方 API Key 无关。",
                        e);
            }
        }

        if (StringUtils.hasText(staticToken)) {
            return staticToken.trim();
        }

        throw new OpenApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(), ErrorCode.INTERNAL_ERROR.getCode(),
                "无法访问中台：OAuth2 未就绪（" + gatewayTokenService.describeWhyNotReady()
                        + "）。请确认 Nacos 已发布共享配置且进程能拉取；或配置 open-api.internal-token");
    }
}
