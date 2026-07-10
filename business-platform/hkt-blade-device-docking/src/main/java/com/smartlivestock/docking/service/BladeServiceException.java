package com.smartlivestock.docking.service;

/**
 * Raised when blade calls fail or blade is not reachable.
 */
public class BladeServiceException extends RuntimeException {
    public BladeServiceException(String message) {
        super(message);
    }

    public BladeServiceException(String message, Throwable cause) {
        super(message, cause);
    }
}
