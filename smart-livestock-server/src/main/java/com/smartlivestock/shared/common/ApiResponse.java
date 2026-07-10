package com.smartlivestock.shared.common;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

import org.slf4j.MDC;

import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    @JsonProperty("code")
    private final String code;

    @JsonProperty("message")
    private final String message;

    @JsonProperty("requestId")
    private final String requestId;

    @JsonProperty("data")
    private final T data;

    private ApiResponse(String code, String message, String requestId, T data) {
        this.code = code;
        this.message = message;
        this.requestId = requestId;
        this.data = data;
    }

    public String getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }

    public String getRequestId() {
        return requestId;
    }

    public T getData() {
        return data;
    }

    private static String currentRequestId() {
        String id = MDC.get("requestId");
        return id != null ? id : UUID.randomUUID().toString();
    }

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(
                ErrorCode.OK.name(),
                "success",
                currentRequestId(),
                data
        );
    }

    public static <T> ApiResponse<T> ok(T data, String requestId) {
        return new ApiResponse<>(
                ErrorCode.OK.name(),
                "success",
                requestId,
                data
        );
    }

    public static <T> ApiResponse<T> error(ErrorCode code, String message) {
        return new ApiResponse<>(
                code.name(),
                message,
                currentRequestId(),
                null
        );
    }

    public static <T> ApiResponse<T> error(ErrorCode code, String message, String requestId) {
        return new ApiResponse<>(
                code.name(),
                message,
                requestId,
                null
        );
    }

    public static <T> ApiResponse<T> errorWithData(ErrorCode code, String message, T data) {
        return new ApiResponse<>(
                code.name(),
                message,
                currentRequestId(),
                data
        );
    }
}
