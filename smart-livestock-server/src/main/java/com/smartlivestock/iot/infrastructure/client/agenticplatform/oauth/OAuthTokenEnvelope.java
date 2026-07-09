package com.smartlivestock.iot.infrastructure.client.agenticplatform.oauth;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

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
        private Integer expiresIn;
    }
}
