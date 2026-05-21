package com.smartlivestock.shared.web;

public final class FarmIdPathParser {

    private FarmIdPathParser() {}

    public static Long extractFarmId(String uri) {
        String[] segments = uri.split("/");
        for (int i = 0; i < segments.length - 1; i++) {
            if ("farms".equals(segments[i])) {
                try {
                    return Long.valueOf(segments[i + 1]);
                } catch (NumberFormatException e) {
                    return null;
                }
            }
        }
        return null;
    }
}
