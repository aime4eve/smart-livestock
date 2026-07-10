package com.ai.openapi.common.exception;

import lombok.Getter;

@Getter
public class OpenApiException extends RuntimeException {

    private final int httpStatus;
    private final String errorCode;

    public OpenApiException(int httpStatus, String errorCode, String message) {
        super(message);
        this.httpStatus = httpStatus;
        this.errorCode = errorCode;
    }

    public OpenApiException(int httpStatus, String errorCode, String message, Throwable cause) {
        super(message, cause);
        this.httpStatus = httpStatus;
        this.errorCode = errorCode;
    }
}
