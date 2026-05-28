package com.smartlivestock.shared.cache;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class RedisCacheService {
    private final StringRedisTemplate redis;

    public void set(String key, String value, Duration ttl) {
        redis.opsForValue().set(key, value, ttl);
    }

    public String get(String key) {
        return redis.opsForValue().get(key);
    }

    public void setHash(String key, Map<String, String> fields) {
        redis.opsForHash().putAll(key, fields);
    }

    public String getHashField(String key, String field) {
        return (String) redis.opsForHash().get(key, field);
    }

    public void addToSet(String key, String... values) {
        redis.opsForSet().add(key, values);
    }

    public Set<String> getSet(String key) {
        return redis.opsForSet().members(key);
    }

    public void delete(String key) {
        redis.delete(key);
    }

    public boolean setIfAbsent(String key, String value, Duration ttl) {
        return Boolean.TRUE.equals(redis.opsForValue().setIfAbsent(key, value, ttl));
    }
}
