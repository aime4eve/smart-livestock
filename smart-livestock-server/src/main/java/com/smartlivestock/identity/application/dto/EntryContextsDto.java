package com.smartlivestock.identity.application.dto;

import java.util.List;

/**
 * Selectable entry contexts for the super-admin picker (design 2026-10-19
 * §4.3). Roles are the static switch whitelist; tenants exclude deleted
 * rows and carry the status/trial flags the picker renders.
 */
public record EntryContextsDto(List<EntryContextDto> roles, List<TenantOptionDto> tenants) {

    public record EntryContextDto(String role, boolean tenantScoped) {
    }

    /**
     * status: active | disabled. trialExpired marks the switch gate outcome
     * (subscription FREE or overdue TRIAL) so the client can grey the row
     * out before the 403 ever happens.
     */
    public record TenantOptionDto(Long id, String name, String status, String phase,
                                  String timezone, long farmCount, boolean trialExpired) {
    }
}
