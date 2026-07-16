package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

/**
 * Agentic-middle-platform internal response envelope shared by all /feign/v1/* endpoints.
 */
@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonIgnoreProperties(ignoreUnknown = true)
public class InternalResponse<T> {

    private int code;
    private boolean success;
    private T data;
    private String msg;

    public boolean isOk() {
        return success && (code == 200 || code == 0);
    }

    /** True when the platform rejected the token (code 401). */
    public boolean isTokenExpired() {
        return code == 401
                || (msg != null && msg.contains("令牌已过期"));
    }
}
