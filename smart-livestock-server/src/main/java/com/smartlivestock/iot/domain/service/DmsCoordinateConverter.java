package com.smartlivestock.iot.domain.service;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.regex.Pattern;

/**
 * Converts a coordinate string in DMS (degrees/minutes/seconds) or decimal form
 * into a decimal {@link BigDecimal} (7 decimal places).
 * <p>
 * Accepted DMS forms: {@code 28°14′47.6″N}, {@code 28°14'47.6"N} (prime/apostrophe
 * and double-prime/quote are interchangeable). Direction letters N/S for latitude,
 * E/W for longitude; S/W yield negative values. A plain decimal such as
 * {@code 28.2465940} is also accepted.
 */
public final class DmsCoordinateConverter {

    // minutes: ′ (U+2032) or ' ; seconds: ″ (U+2033) or "
    private static final Pattern DMS = Pattern.compile(
            "(\\d+)°(\\d+)[\\u2032'](\\d+(?:\\.\\d+)?)[\\u2033\\\"]([NSEW])");

    private static final Pattern DECIMAL = Pattern.compile("^-?\\d+(?:\\.\\d+)?$");

    private DmsCoordinateConverter() {
    }

    public static BigDecimal parse(String input) {
        if (input == null || input.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Coordinate is empty");
        }
        String trimmed = input.trim();

        if (!trimmed.contains("°")) {
            if (!DECIMAL.matcher(trimmed).matches()) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "Invalid decimal coordinate: " + input);
            }
            return new BigDecimal(trimmed).setScale(7, RoundingMode.HALF_UP);
        }

        var m = DMS.matcher(trimmed);
        if (!m.matches()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "Invalid DMS coordinate: " + input);
        }

        int deg = Integer.parseInt(m.group(1));
        int min = Integer.parseInt(m.group(2));
        double sec = Double.parseDouble(m.group(3));
        String dir = m.group(4);

        if (min >= 60 || sec >= 60) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "Invalid minutes/seconds in: " + input);
        }

        double decimal = deg + min / 60.0 + sec / 3600.0;
        if ("S".equals(dir) || "W".equals(dir)) {
            decimal = -decimal;
        }
        return BigDecimal.valueOf(decimal).setScale(7, RoundingMode.HALF_UP);
    }
}
