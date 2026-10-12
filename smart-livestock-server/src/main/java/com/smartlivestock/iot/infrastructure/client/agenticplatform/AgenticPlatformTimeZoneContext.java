package com.smartlivestock.iot.infrastructure.client.agenticplatform;

/**
 * Per-call timezone for Blade (agentic-middle-platform) requests.
 * <p>
 * Blade requires an {@code X-TimeZone} header on its APIs (platform
 * convention, ruling 2026-10-12). The value is the DEVICE's tenant timezone,
 * resolved at each sync entry point and stashed here so the shared Feign
 * interceptor can stamp it on every outgoing request. Always clear in a
 * finally block — the sync paths run on shared executor threads.
 */
public final class AgenticPlatformTimeZoneContext {

    private static final ThreadLocal<String> ZONE = new ThreadLocal<>();

    private AgenticPlatformTimeZoneContext() {
    }

    public static void set(String ianaZone) {
        ZONE.set(ianaZone);
    }

    /** Header value for this call; UTC when unset (neutral default). */
    public static String current() {
        String zone = ZONE.get();
        return zone == null || zone.isBlank() ? "UTC" : zone;
    }

    public static void clear() {
        ZONE.remove();
    }
}
