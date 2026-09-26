package com.smartlivestock.ranch.application.signal;

public class SignalCursorTooOldException extends RuntimeException {
    public SignalCursorTooOldException(String message) {
        super(message);
    }
}
