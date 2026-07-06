package com.ai.openapi.common.exception;

public enum ErrorCode {

    INVALID_REQUEST(400, "INVALID_REQUEST"),
    INVALID_SCOPE(400, "INVALID_SCOPE"),
    INVALID_SN(400, "INVALID_SN"),
    INVALID_SPACE(400, "INVALID_SPACE"),
    UNAUTHORIZED(401, "UNAUTHORIZED"),
    KEY_EXPIRED(401, "KEY_EXPIRED"),
    FORBIDDEN(403, "FORBIDDEN"),
    NOT_FOUND(404, "NOT_FOUND"),
    CONFLICT(409, "CONFLICT"),
    RATE_LIMITED(429, "RATE_LIMITED"),
    INTERNAL_ERROR(500, "INTERNAL_ERROR"),
    UPSTREAM_ERROR(502, "UPSTREAM_ERROR");

    private final int httpStatus;
    private final String code;

    ErrorCode(int httpStatus, String code) {
        this.httpStatus = httpStatus;
        this.code = code;
    }

    public int getHttpStatus() {
        return httpStatus;
    }

    public String getCode() {
        return code;
    }
}
