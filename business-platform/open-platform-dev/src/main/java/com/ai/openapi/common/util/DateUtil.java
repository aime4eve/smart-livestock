package com.ai.openapi.common.util;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

public final class DateUtil {

    private static final DateTimeFormatter INPUT_FORMATTER = DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm:ss");
    private static final ZoneId ZONE = ZoneId.systemDefault();

    private DateUtil() {
    }

    public static String toIso8601(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            LocalDateTime ldt = LocalDateTime.parse(raw.trim(), INPUT_FORMATTER);
            return ZonedDateTime.of(ldt, ZONE).format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        } catch (DateTimeParseException e) {
            return raw;
        }
    }
}
