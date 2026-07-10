package com.smartlivestock.shared.common;

public class ApiException extends RuntimeException {
    private final ErrorCode code;
    private final Object[] messageArgs;

    public ApiException(ErrorCode code, String message) {
        this(code, message, null);
    }

    public ApiException(ErrorCode code, String message, Object[] messageArgs) {
        super(message);
        this.code = code;
        this.messageArgs = messageArgs;
    }

    public ErrorCode getCode() { return code; }

    public Object[] getMessageArgs() { return messageArgs; }
}
