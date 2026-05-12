package com.smartlivestock.shared.cache;

public class CacheKeys {
    public static String livestockPosition(Long id) { return "livestock:position:" + id; }
    public static String farmMembers(Long farmId) { return "farm:" + farmId + ":members"; }
    public static String deviceOnline(Long id) { return "device:online:" + id; }
    public static String jwtBlacklist(String token) { return "jwt:blacklist:" + token; }
    public static String rateLimit(Long userId, String endpoint) {
        return "ratelimit:" + userId + ":" + endpoint;
    }
}
