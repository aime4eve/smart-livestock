package com.smartlivestock.identity.application.command;

/**
 * @param timezone IANA name (ruling 2026-10-12); blank/null resolves to UTC.
 */
public record CreateTenantCommand(String name, String contactName, String contactPhone, String timezone) {

    public CreateTenantCommand {
        timezone = (timezone == null || timezone.isBlank()) ? null : timezone.trim();
    }
}
