package com.smartlivestock.shared.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.UUID;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private static String currentRequestId() {
        String id = MDC.get("requestId");
        return id != null ? id : UUID.randomUUID().toString();
    }

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiResponse<Void>> handleApiException(ApiException ex) {
        String requestId = currentRequestId();
        HttpStatus status = mapToHttpStatus(ex.getCode());
        log.warn("[{}] ApiException {}: {}", requestId, ex.getCode(), ex.getMessage());
        return ResponseEntity
                .status(status)
                .body(ApiResponse.error(ex.getCode(), ex.getMessage(), requestId));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidationException(
            MethodArgumentNotValidException ex) {
        String requestId = currentRequestId();
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .reduce((a, b) -> a + "; " + b)
                .orElse("Validation failed");
        log.warn("[{}] Validation error: {}", requestId, message);
        return ResponseEntity
                .badRequest()
                .body(ApiResponse.error(ErrorCode.VALIDATION_ERROR, message, requestId));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNotFound(NoResourceFoundException ex) {
        String requestId = currentRequestId();
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(ErrorCode.RESOURCE_NOT_FOUND,
                        ex.getResourcePath() != null ? "Not found: " + ex.getResourcePath() : "Not found",
                        requestId));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> handleMethodNotAllowed(
            HttpRequestMethodNotSupportedException ex) {
        String requestId = currentRequestId();
        log.warn("[{}] Method not allowed: {} {}", ex.getMethod(), ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.METHOD_NOT_ALLOWED)
                .body(ApiResponse.error(ErrorCode.BAD_REQUEST,
                        "Method not allowed: " + ex.getMethod(), requestId));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGenericException(Exception ex) {
        String requestId = currentRequestId();
        log.error("[{}] Unexpected error", requestId, ex);
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(ErrorCode.INTERNAL_ERROR,
                        "An unexpected error occurred", requestId));
    }

    private HttpStatus mapToHttpStatus(ErrorCode code) {
        return switch (code) {
            case OK -> HttpStatus.OK;
            case VALIDATION_ERROR, BAD_REQUEST -> HttpStatus.BAD_REQUEST;
            case AUTH_TOKEN_EXPIRED -> HttpStatus.UNAUTHORIZED;
            case AUTH_INVALID_TOKEN -> HttpStatus.UNAUTHORIZED;
            case AUTH_API_KEY_INVALID -> HttpStatus.UNAUTHORIZED;
            case AUTH_API_KEY_EXPIRED -> HttpStatus.UNAUTHORIZED;
            case AUTH_FORBIDDEN -> HttpStatus.FORBIDDEN;
            case TENANT_DISABLED -> HttpStatus.FORBIDDEN;
            case QUOTA_EXCEEDED -> HttpStatus.FORBIDDEN;
            case LICENSE_EXPIRED -> HttpStatus.FORBIDDEN;
            case RESOURCE_NOT_FOUND -> HttpStatus.NOT_FOUND;
            case STATE_CONFLICT -> HttpStatus.CONFLICT;
            case DUPLICATE_RESOURCE -> HttpStatus.CONFLICT;
            case DEVICE_NOT_ACTIVE -> HttpStatus.CONFLICT;
            case RESOURCE_DELETED -> HttpStatus.GONE;
            case FARM_SCOPE_CONFLICT -> HttpStatus.CONFLICT;
            case RATE_LIMIT_EXCEEDED -> HttpStatus.TOO_MANY_REQUESTS;
            case INTERNAL_ERROR -> HttpStatus.INTERNAL_SERVER_ERROR;
        };
    }
}
