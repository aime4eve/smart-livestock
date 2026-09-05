package com.smartlivestock.licensing.infrastructure;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Canonical JSON serializer shared by the license signing and verification
 * pipeline (design section 3).
 * <p>
 * Canonical rules:
 * <ul>
 *   <li>UTF-8 encoding</li>
 *   <li>object keys sorted lexicographically, recursively</li>
 *   <li>compact separators ({@code ,} and {@code :}), no whitespace or newlines</li>
 *   <li>{@link Instant} values rendered as UTC {@code yyyy-MM-dd'T'HH:mm:ss'Z'}</li>
 *   <li>integral numbers rendered without a decimal point</li>
 *   <li>map entries with {@code null} values are omitted; nested {@code null}
 *       outside a map entry context is rejected</li>
 * </ul>
 * Both the Java verifier and the Python issuer must agree byte-for-byte on this
 * form; {@code license-issuer/test-vectors/canonical-json-v1.json} pins it.
 */
public class CanonicalJsonSerializer {

    private static final DateTimeFormatter UTC_SECONDS =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'").withZone(ZoneOffset.UTC);

    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Serialize a map to canonical JSON bytes.
     *
     * @throws DomainException LICENSE_INVALID when the value tree cannot be
     *                         canonicalized (unsupported type, unformattable instant)
     */
    public byte[] serialize(Map<String, Object> value) {
        if (value == null) {
            throw invalid("cannot serialize a null root");
        }
        StringBuilder sb = new StringBuilder();
        writeObject(value, sb);
        return sb.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
    }

    /**
     * Parse JSON bytes into a generic map. Numbers are returned as
     * Integer/Long/Double, objects as LinkedHashMap, strings as String.
     *
     * @throws DomainException LICENSE_INVALID when the bytes are not valid JSON
     */
    public Map<String, Object> parse(byte[] bytes) {
        if (bytes == null || bytes.length == 0) {
            throw invalid("cannot parse empty payload bytes");
        }
        try {
            return objectMapper.readValue(bytes, MAP_TYPE);
        } catch (IOException e) {
            throw invalid("payload is not valid JSON: " + e.getMessage());
        }
    }

    // ── Canonical writers ────────────────────────────────────────────

    private void writeObject(Map<String, Object> map, StringBuilder sb) {
        TreeMap<String, Object> sorted = new TreeMap<>(map);
        sb.append('{');
        boolean first = true;
        for (Map.Entry<String, Object> entry : sorted.entrySet()) {
            if (entry.getValue() == null) {
                // Canonical form omits entries with absent values.
                continue;
            }
            if (!first) {
                sb.append(',');
            }
            first = false;
            writeString(entry.getKey(), sb);
            sb.append(':');
            writeValue(entry.getValue(), sb);
        }
        sb.append('}');
    }

    private void writeArray(List<?> list, StringBuilder sb) {
        sb.append('[');
        boolean first = true;
        for (Object item : list) {
            if (item == null) {
                throw invalid("arrays must not contain null values");
            }
            if (!first) {
                sb.append(',');
            }
            first = false;
            writeValue(item, sb);
        }
        sb.append(']');
    }

    private void writeValue(Object value, StringBuilder sb) {
        if (value == null) {
            throw invalid("null values are not part of the canonical form");
        }
        if (value instanceof Map<?, ?> map) {
            @SuppressWarnings("unchecked")
            Map<String, Object> stringMap = (Map<String, Object>) map;
            writeObject(stringMap, sb);
        } else if (value instanceof List<?> list) {
            writeArray(list, sb);
        } else if (value instanceof String s) {
            writeString(s, sb);
        } else if (value instanceof Instant instant) {
            sb.append('"').append(UTC_SECONDS.format(instant.truncatedTo(ChronoUnit.SECONDS))).append('"');
        } else if (value instanceof Boolean b) {
            sb.append(b);
        } else if (value instanceof Byte || value instanceof Short || value instanceof Integer
                || value instanceof Long || value instanceof BigInteger) {
            sb.append(value);
        } else if (value instanceof Number n) {
            writeNumber(n, sb);
        } else {
            throw invalid("unsupported canonical JSON value type: " + value.getClass().getName());
        }
    }

    /**
     * Render a non-integral number. Values that are mathematically integral are
     * emitted without a decimal point so that a Double {@code 5.0} and an
     * Integer {@code 5} canonicalize identically.
     */
    private void writeNumber(Number number, StringBuilder sb) {
        BigDecimal decimal = new BigDecimal(number.toString());
        BigDecimal stripped = decimal.stripTrailingZeros();
        if (stripped.scale() <= 0) {
            sb.append(stripped.toBigInteger());
        } else {
            sb.append(stripped.toPlainString());
        }
    }

    private void writeString(String value, StringBuilder sb) {
        sb.append('"');
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\b' -> sb.append("\\b");
                case '\f' -> sb.append("\\f");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                default -> {
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        // Non-ASCII characters stay raw; the form is UTF-8.
                        sb.append(c);
                    }
                }
            }
        }
        sb.append('"');
    }

    private static DomainException invalid(String detail) {
        return new DomainException(ErrorCode.LICENSE_INVALID, "canonical JSON error: " + detail);
    }
}
