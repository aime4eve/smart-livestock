package com.ai.openapi.common.exception;

import com.ai.openapi.common.response.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.MessageSourceResolvable;
import org.springframework.context.support.DefaultMessageSourceResolvable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.validation.method.ParameterValidationResult;

import feign.FeignException;

import java.util.Locale;
import java.util.stream.Collectors;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(OpenApiException.class)
    public ResponseEntity<ErrorResponse> handleOpenApiException(OpenApiException ex, HttpServletRequest request) {
        log.warn("OpenApiException: {} - {} - {}", ex.getErrorCode(), ex.getMessage(), request.getRequestURI());
        ErrorResponse error = new ErrorResponse(ex.getErrorCode(), ex.getMessage(), generateRequestId(request));
        return ResponseEntity.status(ex.getHttpStatus()).body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationException(MethodArgumentNotValidException ex, HttpServletRequest request) {
        String detail = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + ": " + e.getDefaultMessage())
                .collect(Collectors.collectingAndThen(Collectors.toList(),
                        errs -> errs.isEmpty() ? "请求参数不合法" : String.join("; ", errs)));
        log.warn("Validation error: {} - {}", detail, request.getRequestURI());
        ErrorResponse error = new ErrorResponse(ErrorCode.INVALID_REQUEST.getCode(), detail, generateRequestId(request));
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(
            ConstraintViolationException ex, HttpServletRequest request) {
        String detail = ex.getConstraintViolations().stream()
                .map(this::formatConstraintViolation)
                .collect(Collectors.collectingAndThen(Collectors.toList(),
                        errs -> errs.isEmpty() ? "请求参数不合法" : String.join("; ", errs)));
        log.warn("ConstraintViolation: {} - {}", detail, request.getRequestURI());
        ErrorResponse error = new ErrorResponse(ErrorCode.INVALID_REQUEST.getCode(), detail, generateRequestId(request));
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }

    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<ErrorResponse> handleHandlerMethodValidation(
            HandlerMethodValidationException ex, HttpServletRequest request) {
        String detail = ex.getParameterValidationResults().stream()
                .flatMap(r -> r.getResolvableErrors().stream().map(err -> formatMethodParameterError(r, err)))
                .collect(Collectors.joining("; "));
        if (detail.isEmpty()) {
            detail = "请求参数不合法";
        }
        log.warn("Method validation error: {} - {}", detail, request.getRequestURI());
        ErrorResponse error = new ErrorResponse(ErrorCode.INVALID_REQUEST.getCode(), detail, generateRequestId(request));
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleMethodArgumentTypeMismatch(
            MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
        Class<?> rt = ex.getRequiredType();
        String typeHint = rt != null ? rt.getSimpleName() : "?";
        String detail = String.format("参数 \"%s\" 取值非法或与期望类型(%s)不匹配", ex.getName(), typeHint);
        log.warn("Type mismatch: {} - {}", detail, request.getRequestURI());
        ErrorResponse error = new ErrorResponse(ErrorCode.INVALID_REQUEST.getCode(), detail, generateRequestId(request));
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErrorResponse> handleMissingServletRequestParameter(
            MissingServletRequestParameterException ex, HttpServletRequest request) {
        String detail = String.format("缺少必填参数 \"%s\"", ex.getParameterName());
        log.warn("Missing parameter: {} - {}", detail, request.getRequestURI());
        ErrorResponse error = new ErrorResponse(ErrorCode.INVALID_REQUEST.getCode(), detail, generateRequestId(request));
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleHttpMessageNotReadable(
            HttpMessageNotReadableException ex, HttpServletRequest request) {
        // 优先提取 Jackson 解析阶段的原始错误信息（如自定义 Deserializer 抛出的友好提示）
        String original = ex.getMessage();
        String detail = "请求体格式错误或无法解析为 JSON";
        if (original != null) {
            // Jackson JSON parse error: ... 提取冒号后面的核心信息
            int colonIdx = original.indexOf(": ");
            if (colonIdx >= 0) {
                String afterColon = original.substring(colonIdx + 2).trim();
                // 去掉 Java 类名前缀，只保留可读描述
                int bracketIdx = afterColon.indexOf(" at [");
                String readable = bracketIdx > 0 ? afterColon.substring(0, bracketIdx).trim() : afterColon;
                if (!readable.isEmpty()) {
                    detail = readable;
                }
            }
        }
        log.warn("Unreadable body: {} - {}", request.getRequestURI(), original);
        ErrorResponse error = new ErrorResponse(ErrorCode.INVALID_REQUEST.getCode(),
                detail, generateRequestId(request));
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }

    /**
     * 换票链路历史上曾抛出 {@link IllegalStateException}，会落入通用 handler 变成「服务端内部错误」。
     * 兜底映射为 502，便于调用方与网关日志对齐排查（新版已改为 {@link OpenApiException}）。
     */
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<ErrorResponse> handleIllegalStateForOAuthTokenExchange(
            IllegalStateException ex, HttpServletRequest request) {
        String msg = ex.getMessage();
        if (msg != null && (msg.contains("换票") || msg.contains("网关 OAuth2"))) {
            log.warn("OAuth token exchange (IllegalStateException): {} - {}", msg, request.getRequestURI());
            String detail = "访问中台失败：换取访问令牌被认证服务拒绝或服务异常。"
                    + "请管理员核对 Nacos 中 open-api.oauth2 的 client-id、client-secret 是否与网关 OAuth2 客户端一致。"
                    + "（网关常见提示：用户名或密码错误，与调用方 API Key 无关。）"
                    + " 详情：" + msg;
            ErrorResponse error = new ErrorResponse(ErrorCode.UPSTREAM_ERROR.getCode(), detail,
                    generateRequestId(request));
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(error);
        }
        log.error("Unexpected error: {} - {}", request.getRequestURI(), msg, ex);
        ErrorResponse error = new ErrorResponse(ErrorCode.INTERNAL_ERROR.getCode(), "服务端内部错误",
                generateRequestId(request));
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }

    /**
     * Feign 调用设备/空间等下游失败时，避免对调用方展示「服务端内部错误」，改为明确的中台不可用类说明。
     */
    @ExceptionHandler(FeignException.class)
    public ResponseEntity<ErrorResponse> handleFeignException(FeignException ex, HttpServletRequest request) {
        int status = ex.status();
        String raw = ex.getMessage() != null ? ex.getMessage() : "";
        String detail = buildUpstreamUnavailableMessage(status, raw, ex, request.getRequestURI());
        log.warn("Feign upstream error: status={} path={} — {}", status, request.getRequestURI(), raw);
        ErrorResponse error = new ErrorResponse(ErrorCode.UPSTREAM_ERROR.getCode(), detail,
                generateRequestId(request));
        return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(error);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpectedException(Exception ex, HttpServletRequest request) {
        log.error("Unexpected error: {} - {}", request.getRequestURI(), ex.getMessage(), ex);
        ErrorResponse error = new ErrorResponse(ErrorCode.INTERNAL_ERROR.getCode(), "服务端内部错误", generateRequestId(request));
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }

    private static String buildUpstreamUnavailableMessage(int httpStatus, String feignMessage, FeignException ex,
                                                            String openApiPath) {
        String label = upstreamLabel(openApiPath);
        String msg = feignMessage != null ? feignMessage : "";
        String lower = msg.toLowerCase(Locale.ROOT);
        if (httpStatus == 503
                || msg.contains("Load balancer does not contain")
                || msg.contains("No servers available")) {
            return "无法连接" + label + "：当前没有可用的下游服务实例（未在注册中心注册或未启动）。"
                    + "请确认对应微服务已启动，且与 Open API 使用同一注册中心与命名空间。";
        }
        if (httpStatus == 504 || lower.contains("timeout") || lower.contains("timed out")) {
            return label + "响应超时，请稍后重试。";
        }
        if (httpStatus < 0 || lower.contains("connection refused") || lower.contains("failed to connect")) {
            return "无法连接" + label + "，请检查网络连通性与服务发现配置。";
        }
        if (httpStatus >= 500) {
            return label + "异常或无响应（下游 HTTP " + httpStatus + "），请稍后重试或联系管理员。";
        }
        if (httpStatus >= 400) {
            return "调用" + label + "被拒绝（下游 HTTP " + httpStatus + "）。";
        }
        Throwable cause = ex.getCause();
        if (cause != null) {
            String c = cause.getMessage() != null ? cause.getMessage().toLowerCase(Locale.ROOT) : "";
            if (c.contains("timeout") || c.contains("timed out")) {
                return label + "响应超时，请稍后重试。";
            }
            if (c.contains("connection refused") || c.contains("no route to host")) {
                return "无法连接" + label + "，请检查网络连通性与服务地址。";
            }
        }
        String tail = msg.length() > 240 ? msg.substring(0, 240) + "…" : msg;
        return "访问" + label + "失败，请稍后重试。" + (tail.isEmpty() ? "" : " 详情：" + tail);
    }

    /** 按开放 API 路径区分文案，避免设备与空间接口提示混淆。 */
    private static String upstreamLabel(String openApiPath) {
        if (openApiPath != null && openApiPath.startsWith("/v1/spaces")) {
            return "空间服务中台";
        }
        if (openApiPath != null && (openApiPath.startsWith("/v1/devices") || openApiPath.contains("/devices/"))) {
            return "设备中台";
        }
        return "业务中台";
    }

    private String formatMethodParameterError(ParameterValidationResult r, MessageSourceResolvable err) {
        String name = r.getMethodParameter().getParameterName();
        if (name == null) {
            name = "param";
        }
        try {
            ConstraintViolation<?> cv = r.unwrap(err, ConstraintViolation.class);
            if (cv != null) {
                return name + ": " + cv.getMessage();
            }
        } catch (Exception ignored) {
            // fall through
        }
        if (err instanceof DefaultMessageSourceResolvable d) {
            String m = d.getDefaultMessage();
            if (m != null) {
                return name + ": " + m;
            }
        }
        return name + ": " + err;
    }

    private String formatConstraintViolation(ConstraintViolation<?> v) {
        String path = v.getPropertyPath() != null ? v.getPropertyPath().toString() : "";
        int idx = Math.max(Math.max(path.lastIndexOf('.'), path.lastIndexOf('[')),
                Math.max(path.lastIndexOf('|'), path.lastIndexOf(',')));
        String shortName = idx >= 0 ? path.substring(idx + 1) : path;
        return shortName + ": " + v.getMessage();
    }

    private String generateRequestId(HttpServletRequest request) {
        String traceId = request.getHeader("X-Trace-Id");
        if (traceId != null && !traceId.isEmpty()) {
            return traceId;
        }
        return java.util.UUID.randomUUID().toString().replace("-", "").substring(0, 16);
    }
}
