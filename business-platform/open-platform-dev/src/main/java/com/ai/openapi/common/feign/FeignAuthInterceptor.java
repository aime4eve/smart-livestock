package com.ai.openapi.common.feign;

import feign.RequestInterceptor;
import feign.RequestTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * 为 Feign 访问中台设置令牌请求头。默认与中台约定一致：请求头名 {@code token}，值为 access_token 原文（无前缀、不用 {@code Authorization}）。
 * <p>
 * 若环境仍要求 {@code Authorization: Bearer ...}，可通过 {@code open-api.feign-auth.header-name} /
 * {@code open-api.feign-auth.token-prefix} 覆盖。
 * <p>
 * 调用开放 API 的客户端只需传 API Key；鉴权通过后由 {@link InternalTokenProvider} 换票后再带此头访问中台。
 */
@Component
public class FeignAuthInterceptor implements RequestInterceptor {

    private final InternalTokenProvider tokenProvider;

    /** 中台常见为 {@code token}，少数为 {@code Authorization}。 */
    @Value("${open-api.feign-auth.header-name:token}")
    private String headerName;

    /** 空串表示值仅为 access_token；若需 Bearer，设为 {@code Bearer }（注意末尾空格）。 */
    @Value("${open-api.feign-auth.token-prefix:}")
    private String tokenPrefix;

    public FeignAuthInterceptor(InternalTokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @Override
    public void apply(RequestTemplate template) {
        String prefix = tokenPrefix != null ? tokenPrefix : "";
        template.header(headerName, prefix + tokenProvider.getToken());
    }
}
