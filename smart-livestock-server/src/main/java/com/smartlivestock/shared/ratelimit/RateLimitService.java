package com.smartlivestock.shared.ratelimit;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RateLimitService {

    private final StringRedisTemplate redis;

    /**
     * Lua script for atomic sliding-window rate limit check + record.
     * KEYS[1] = rate limit key
     * ARGV[1] = now (epoch ms)
     * ARGV[2] = window start (now - windowMs)
     * ARGV[3] = member (unique id for this request)
     * ARGV[4] = limit
     * ARGV[5] = TTL in seconds (window * 2)
     *
     * Returns: {allowed (1/0), currentCount, limit}
     */
    private static final String LUA_SCRIPT = """
            local key = KEYS[1]
            local now = tonumber(ARGV[1])
            local windowStart = tonumber(ARGV[2])
            local member = ARGV[3]
            local limit = tonumber(ARGV[4])
            local ttl = tonumber(ARGV[5])

            redis.call('ZREMRANGEBYSCORE', key, 0, windowStart)
            local count = redis.call('ZCARD', key)

            if count >= limit then
                redis.call('EXPIRE', key, ttl)
                return {0, count, limit}
            end

            redis.call('ZADD', key, now, member)
            redis.call('EXPIRE', key, ttl)
            return {1, count + 1, limit}
            """;

    private final DefaultRedisScript<List> script = new DefaultRedisScript<>(LUA_SCRIPT, List.class);

    /**
     * Atomic check-and-record using Redis Lua script.
     * Returns the result with remaining count info.
     */
    public RateLimitResult checkAndRecord(String key, int limit, Duration window) {
        long now = Instant.now().toEpochMilli();
        long windowStart = now - window.toMillis();
        String member = now + ":" + UUID.randomUUID();
        long ttlSeconds = window.multipliedBy(2).getSeconds();

        List<Long> result = redis.execute(
                script,
                List.of(key),
                String.valueOf(now),
                String.valueOf(windowStart),
                member,
                String.valueOf(limit),
                String.valueOf(ttlSeconds)
        );

        long allowed = result.get(0);
        long current = result.get(1);
        long limitVal = result.get(2);

        return new RateLimitResult(
                allowed == 1,
                (int) limitVal,
                (int) Math.max(0, limitVal - current),
                windowStart + window.toMillis()
        );
    }

    public record RateLimitResult(
            boolean allowed,
            int limit,
            int remaining,
            long resetAtEpochMs
    ) {}
}
