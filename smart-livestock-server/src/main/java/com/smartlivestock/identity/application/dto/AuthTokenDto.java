package com.smartlivestock.identity.application.dto;

/**
 * impersonated: true only for switched context tokens (super-admin role
 * entry, design 2026-10-19 §4.2) — the user DTO then carries the effective
 * context identity, not the super admin's stored row.
 */
public record AuthTokenDto(String accessToken, UserDto user, Boolean impersonated) {

    public AuthTokenDto(String accessToken, UserDto user) {
        this(accessToken, user, false);
    }
}
