package com.smartlivestock.identity.application.dto;

import com.smartlivestock.identity.domain.model.User;

public record UserDto(
        Long id,
        String name,
        String phone,
        String role,
        Long tenantId,
        boolean active
) {
    public static UserDto from(User user) {
        return new UserDto(
                user.getId(),
                user.getName(),
                user.getPhone(),
                user.getRole().name(),
                user.getTenantId(),
                user.isActive()
        );
    }
}
