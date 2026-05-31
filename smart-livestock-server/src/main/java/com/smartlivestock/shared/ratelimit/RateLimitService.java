package com.smartlivestock.shared.ratelimit;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RateLimitService {

    private final StringRedisTemplate redis;

    /**
     * Check and record a request against the rate limit using a Redis sorted-set
     * sliding window. Returns the result with remaining count info.
     */
    public RateLimitResult checkAndRecord(String key, int limit, Duration window) {
        long now = Instant.now().toEpochMilli();
        long windowStart = now - window.toMillis();
        String member = now + ":" + UUID.randomUUID().toString();

        ZSetOperations<String, String> zset = redis.opsForZSet();

        // Remove expired entries
        zset.removeRangeByScore(key, 0, windowStart);

        // Count current window
        Long count = zset.zCard(key);
        int current = count != null ? count.intValue() : 0;

        if (current >= limit) {
            // Rate exceeded — set TTL on the key for auto-cleanup
            redis.expire(key, window.multipliedBy(2));
            return new RateLimitResult(false, limit, 0, windowStart + window.toMillis());
        }

        // Record this request
        zset.add(key, member, now);
        redis.expire(key, window.multipliedBy(2));

        return new RateLimitResult(true, limit, limit - current - 1, windowStart + window.toMillis());
    }

    public record RateLimitResult(
            boolean allowed,
            int limit,
            int remaining,
            long resetAtEpochMs
    ) {}
}
