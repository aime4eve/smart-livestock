package com.smartlivestock.shared.security;

import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Context-token "act" delegation claim (design 2026-10-19 §4.2): the claim
 * must be carried on generation and survive refresh unchanged, while plain
 * tokens keep their existing shape.
 */
class JwtTokenProviderTest {

    private final JwtTokenProvider provider =
            new JwtTokenProvider("unit-test-secret-0123456789abcdef0123456789abcdef", 3600000L);

    @Test
    void contextToken_carriesActClaim() {
        String token = provider.generateToken(9L, 2L, "OWNER",
                Map.of("sub", 9L, "role", "SUPER_ADMIN"));

        Claims claims = provider.parseToken(token);
        assertThat(claims.getSubject()).isEqualTo("9");
        assertThat(claims.get("tid")).isEqualTo(2);
        assertThat(claims.get("role")).isEqualTo("OWNER");

        @SuppressWarnings("unchecked")
        Map<String, Object> act = (Map<String, Object>) claims.get("act");
        assertThat(act).isNotNull();
        assertThat(act.get("role")).isEqualTo("SUPER_ADMIN");
    }

    @Test
    void refresh_preservesActClaim() {
        String token = provider.generateToken(9L, 2L, "B2B_ADMIN",
                Map.of("sub", 9L, "role", "SUPER_ADMIN"));

        String refreshed = provider.refreshToken(token);
        assertThat(refreshed).isNotNull();

        Claims claims = provider.parseToken(refreshed);
        assertThat(claims.getSubject()).isEqualTo("9");
        assertThat(claims.get("tid")).isEqualTo(2);
        assertThat(claims.get("role")).isEqualTo("B2B_ADMIN");
        @SuppressWarnings("unchecked")
        Map<String, Object> act = (Map<String, Object>) claims.get("act");
        assertThat(act).isNotNull();
        assertThat(act.get("role")).isEqualTo("SUPER_ADMIN");
    }

    @Test
    void plainToken_hasNoActClaim_beforeAndAfterRefresh() {
        String token = provider.generateToken(1L, null, "PLATFORM_ADMIN");

        Claims claims = provider.parseToken(token);
        assertThat(claims.get("act")).isNull();

        String refreshed = provider.refreshToken(token);
        assertThat(provider.parseToken(refreshed).get("act")).isNull();
    }
}
