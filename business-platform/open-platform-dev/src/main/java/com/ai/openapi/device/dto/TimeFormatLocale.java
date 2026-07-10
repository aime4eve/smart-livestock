package com.ai.openapi.device.dto;

import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 时间格式区域枚举，用于根据请求头标识决定时间参数的校验格式。
 */
public enum TimeFormatLocale {

    ZH("zh", "yyyy-MM-dd HH:mm:ss", "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}"),
    EN("en", "MM/dd/yyyy HH:mm:ss", "\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2}");

    private final String code;
    private final String pattern;
    private final String regex;

    TimeFormatLocale(String code, String pattern, String regex) {
        this.code = code;
        this.pattern = pattern;
        this.regex = regex;
    }

    public String getPattern() {
        return pattern;
    }

    /**
     * 根据请求头值解析枚举，不匹配时默认中文。
     */
    public static TimeFormatLocale fromHeader(String headerValue) {
        if (headerValue != null && headerValue.trim().equalsIgnoreCase("en")) {
            return EN;
        }
        return ZH;
    }

    /**
     * 校验时间字符串格式，不匹配则抛出 INVALID_REQUEST。
     */
    public void validate(String fieldName, String value) {
        if (value == null || value.isBlank()) {
            throw new OpenApiException(ErrorCode.INVALID_REQUEST.getHttpStatus(),
                    ErrorCode.INVALID_REQUEST.getCode(), fieldName + " 不能为空");
        }
        if (!value.trim().matches(regex)) {
            throw new OpenApiException(ErrorCode.INVALID_REQUEST.getHttpStatus(),
                    ErrorCode.INVALID_REQUEST.getCode(),
                    fieldName + " 格式错误: '" + value + "'，正确格式为 " + pattern);
        }
    }

    /**
     * 将时间字符串转换为上游要求的格式（MM/dd/yyyy HH:mm:ss）。
     */
    public String convertToUpstreamFormat(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        LocalDateTime ldt = LocalDateTime.parse(value.trim(), DateTimeFormatter.ofPattern(pattern));
        return ldt.format(DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm:ss"));
    }
}
