package com.smartlivestock.shared.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

@Component
public class JwtTokenProvider {

    private final SecretKey key;
    private final long accessExpiration;

    /** Grace period for token refresh: allow tokens expired within 30 minutes. */
    private static final long REFRESH_GRACE_MS = 30 * 60 * 1000L;

    public JwtTokenProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-expiration}") long accessExpiration
    ) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessExpiration = accessExpiration;
    }

    public String generateToken(Long userId, Long tenantId, String role) {
        return generateToken(userId, tenantId, role, null);
    }

    /**
     * Context tokens (super-admin role entry, design 2026-10-19 §4.2) carry an
     * RFC 8693 style "act" delegation claim: sub keeps pointing at the real
     * super-admin user while role/tid carry the chosen entry context, so the
     * token stays structurally identical to a real user token. The act claim
     * must survive refresh unchanged (see {@link #refreshToken}).
     */
    public String generateToken(Long userId, Long tenantId, String role, Map<String, Object> act) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + accessExpiration);

        JwtBuilder builder = Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("tid", tenantId)
                .claim("role", role);
        if (act != null && !act.isEmpty()) {
            builder.claim("act", act);
        }
        return builder
                .issuedAt(now)
                .expiration(expiry)
                .signWith(key)
                .compact();
    }

    public Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long getUserIdFromToken(String token) {
        Claims claims = parseToken(token);
        return Long.valueOf(claims.getSubject());
    }

    public Long getTenantIdFromToken(String token) {
        Claims claims = parseToken(token);
        return claims.get("tid", Long.class);
    }

    public String getRoleFromToken(String token) {
        Claims claims = parseToken(token);
        return claims.get("role", String.class);
    }

    public boolean isTokenValid(String token) {
        try {
            parseToken(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    /**
     * Refresh: accept a valid or recently-expired access token, issue a new one.
     * Returns null if the token is too old or invalid.
     */
    public String refreshToken(String token) {
        Claims claims;
        try {
            claims = parseToken(token);
        } catch (ExpiredJwtException e) {
            claims = e.getClaims();
            long expiredAt = e.getClaims().getExpiration().getTime();
            long now = System.currentTimeMillis();
            if (now - expiredAt > REFRESH_GRACE_MS) {
                return null;
            }
        } catch (JwtException | IllegalArgumentException e) {
            return null;
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> act = (Map<String, Object>) claims.get("act");
        return generateToken(
                Long.valueOf(claims.getSubject()),
                claims.get("tid", Long.class),
                claims.get("role", String.class),
                act
        );
    }
}
