package com.smartlivestock.iot.infrastructure.client.agenticplatform.client;

/**
 * Raised when agentic-middle-platform calls fail or the platform is not reachable.
 */
public class AgenticPlatformServiceException extends RuntimeException {
    public AgenticPlatformServiceException(String message) {
        super(message);
    }

    public AgenticPlatformServiceException(String message, Throwable cause) {
        super(message, cause);
    }
}
