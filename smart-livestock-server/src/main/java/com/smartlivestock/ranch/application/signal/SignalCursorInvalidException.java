package com.smartlivestock.ranch.application.signal;

public class SignalCursorInvalidException extends RuntimeException {
    public SignalCursorInvalidException(String message) {
        super(message);
    }

    public SignalCursorInvalidException(String message, Throwable cause) {
        super(message, cause);
    }
}
