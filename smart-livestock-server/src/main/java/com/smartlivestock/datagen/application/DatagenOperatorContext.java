package com.smartlivestock.datagen.application;

public record DatagenOperatorContext(
        Long userId, Long tenantId, DatagenOperatorRole role) {

    public enum DatagenOperatorRole { PLATFORM_ADMIN, B2B_ADMIN }

    public boolean isPlatformAdmin() {
        return role == DatagenOperatorRole.PLATFORM_ADMIN;
    }
}
