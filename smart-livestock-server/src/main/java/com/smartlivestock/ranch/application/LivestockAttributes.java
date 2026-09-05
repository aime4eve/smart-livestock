package com.smartlivestock.ranch.application;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;

import java.util.Map;

/**
 * Canonical livestock attribute values accepted by the database CHECK
 * constraints (V2 {@code chk_livestock_gender}, V20260702150000
 * {@code chk_livestock_breed}). Input is normalized here — including the
 * historical Chinese aliases carried over by that migration — so callers get
 * a clean VALIDATION_ERROR instead of an opaque 500 when the database would
 * reject the row.
 */
final class LivestockAttributes {

    private LivestockAttributes() {
    }

    private static final Map<String, String> BREED_ALIASES = Map.ofEntries(
            Map.entry("ANGUS", "ANGUS"),
            Map.entry("安格斯", "ANGUS"),
            Map.entry("安格斯牛", "ANGUS"),
            Map.entry("WAGYU", "WAGYU"),
            Map.entry("和牛", "WAGYU"),
            Map.entry("SIMMENTAL", "SIMMENTAL"),
            Map.entry("西门塔尔", "SIMMENTAL"),
            Map.entry("西门塔尔牛", "SIMMENTAL"),
            Map.entry("LIMOUSIN", "LIMOUSIN"),
            Map.entry("利木赞", "LIMOUSIN"),
            Map.entry("利木赞牛", "LIMOUSIN"));

    private static final String BREED_ALLOWED = "ANGUS/WAGYU/SIMMENTAL/LIMOUSIN/OTHER";

    /**
     * Canonical breed code; null/blank maps to OTHER, matching the migrating
     * UPDATEs that normalized legacy rows.
     */
    static String normalizeBreed(String raw) {
        if (raw == null || raw.isBlank()) {
            return "OTHER";
        }
        String trimmed = raw.trim();
        String canonical = BREED_ALIASES.get(trimmed);
        if (canonical == null) {
            canonical = BREED_ALIASES.get(trimmed.toUpperCase());
        }
        if (canonical == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.livestockBreedInvalid",
                    new Object[]{raw, BREED_ALLOWED});
        }
        return canonical;
    }

    /** Canonical gender code; null stays null (the column is nullable). */
    static String normalizeGender(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String upper = raw.trim().toUpperCase();
        if (upper.equals("MALE") || upper.equals("FEMALE")) {
            return upper;
        }
        throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.livestockGenderInvalid",
                new Object[]{raw, "MALE/FEMALE"});
    }
}
