package com.smartlivestock.identity.application.command;

/**
 * Context switch request (super-admin role entry, design 2026-10-19 §4.3):
 * target role + optional target tenant. tenantId is required for tenant-
 * scoped roles (B2B_ADMIN/OWNER/WORKER) and ignored for PLATFORM_ADMIN.
 */
public record SwitchContextCommand(String role, Long tenantId) {
}
