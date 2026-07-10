package com.ai.openapi.common.feign.oauth;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

/**
 * 认证服务包装的 Token 响应（与网关约定一致）。
 */
@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonIgnoreProperties(ignoreUnknown = true)
public class OAuthTokenEnvelope {

    private int code;
    private boolean success;
    private String msg;
    private OAuthTokenData data;

    @Data
    @JsonInclude(JsonInclude.Include.NON_NULL)
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class OAuthTokenData {

        private String accessToken;
        private String tokenType;
        /** 有效期（秒），如 43200 */
        private Integer expiresIn;
    }
}
