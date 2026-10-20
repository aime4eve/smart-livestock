package com.smartlivestock.identity.domain.model;

public enum Role {
    OWNER,
    WORKER,
    PLATFORM_ADMIN,
    B2B_ADMIN,
    API_CONSUMER,
    /**
     * Root-login-only role: holds no business authority of its own and
     * enters the system via switched context tokens (design 2026-10-19,
     * section 4.1) — the root token can only pick/switch an entry context.
     */
    SUPER_ADMIN
}
