package com.smartlivestock.shared.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * Request-scoped flag for a super-admin switched-context session (design
 * 2026-10-19 §4.2). {@link JwtAuthenticationFilter} attaches {@link Marker} as
 * the Authentication details when the JWT carries the "act" delegation claim,
 * so application services can tell a switched context (sub is the real super
 * admin, which holds no farm membership rows) apart from a directly logged-in
 * user. The marker rides on the Authentication itself and is therefore dropped
 * together with the SecurityContext after each request.
 */
public final class SwitchedContext {

    private SwitchedContext() {
    }

    /**
     * Authentication details marker; carries the acting super admin id, which
     * is also the token subject (and thus the request principal).
     */
    public record Marker(Long superAdminUserId) {
    }

    /**
     * True when the current request is authenticated with a switched-context
     * token. Anonymous, API-key and directly logged-in requests return false.
     */
    public static boolean isCurrent() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.getDetails() instanceof Marker;
    }
}
