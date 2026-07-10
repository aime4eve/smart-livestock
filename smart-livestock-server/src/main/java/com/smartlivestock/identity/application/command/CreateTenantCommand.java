package com.smartlivestock.identity.application.command;

public record CreateTenantCommand(String name, String contactName, String contactPhone) {
}
