package com.ai.openapi.common.validation;

/**
 * 对外开放 API 的通用正则；ID 假定与后端一致为数字（拒绝中文、字母、空白等），
 * 且整段数字长度不超过 {@value #MAX_DIGITS} 位。
 */
public final class OpenApiPatterns {

    /** 对外开放 API 中允许的数字 ID 字符串最大位数（含）。 */
    public static final int MAX_DIGITS = 21;

    private OpenApiPatterns() {
    }

    /** 必填数字 ID：1～{@value #MAX_DIGITS} 位十进制数字。 */
    public static final String NUMERIC_ID = "^\\d{1," + MAX_DIGITS + "}$";

    /** 可选数字 ID：空串或未传(null)；若有内容则至多 {@value #MAX_DIGITS} 位十进制数字。 */
    public static final String OPTIONAL_NUMERIC_ID = "^\\d{0," + MAX_DIGITS + "}$";
}
