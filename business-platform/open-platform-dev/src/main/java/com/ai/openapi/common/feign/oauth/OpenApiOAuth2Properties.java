package com.ai.openapi.common.feign.oauth;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 经统一网关调用中台时，用 OAuth2 {@code grant_type=openapi} 换取访问令牌。
 */
@Data
@Component
@ConfigurationProperties(prefix = "open-api.oauth2")
public class OpenApiOAuth2Properties {

    /**
     * 为 true 且 token-uri/client 配置齐全、且请求上下文中有 internalUserId 时，
     * Feign 将使用网关返回的 Bearer accessToken。
     */
    private boolean enabled = false;

    private String tokenUri = "";

    private String clientId = "";

    /**
     * 与 client-id 组成 Basic Auth，勿提交明文；可用环境变量注入。
     */
    private String clientSecret = "";

    /** 令牌缓存提前失效时间（秒），避免边界时刻 401 */
    private int expirySkewSeconds = 120;

    /** 连接超时毫秒 */
    private int connectTimeoutMs = 5000;

    /** 读超时毫秒 */
    private int readTimeoutMs = 15000;
}
