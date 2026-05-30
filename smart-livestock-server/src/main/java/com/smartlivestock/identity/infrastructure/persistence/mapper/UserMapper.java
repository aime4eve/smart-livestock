package com.smartlivestock.identity.infrastructure.persistence.mapper;

import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserJpaEntity;

public final class UserMapper {

    private UserMapper() {}

    public static UserJpaEntity toJpaEntity(User user) {
        UserJpaEntity jpa = new UserJpaEntity();
        jpa.setId(user.getId());
        jpa.setPasswordHash(user.getPasswordHash());
        jpa.setName(user.getName());
        jpa.setPhone(user.getPhone());
        jpa.setRole(user.getRole().name());
        jpa.setTenantId(user.getTenantId());
        jpa.setIsActive(user.isActive());
        jpa.setLastLoginAt(user.getLastLoginAt());
        return jpa;
    }

    /**
     * Update an existing JPA entity from domain model.
     * Preserves createdAt/updatedAt which are managed by JPA lifecycle callbacks.
     */
    public static void updateEntity(UserJpaEntity jpa, User user) {
        jpa.setPasswordHash(user.getPasswordHash());
        jpa.setName(user.getName());
        jpa.setPhone(user.getPhone());
        jpa.setRole(user.getRole().name());
        jpa.setTenantId(user.getTenantId());
        jpa.setIsActive(user.isActive());
        jpa.setLastLoginAt(user.getLastLoginAt());
    }

    public static User toDomain(UserJpaEntity jpa) {
        User user = new User();
        user.setId(jpa.getId());
        user.setPasswordHash(jpa.getPasswordHash());
        user.setName(jpa.getName());
        user.setPhone(jpa.getPhone());
        user.setRole(Role.valueOf(jpa.getRole()));
        user.setTenantId(jpa.getTenantId());
        user.reconstituteActive(Boolean.TRUE.equals(jpa.getIsActive()));
        user.reconstituteLastLoginAt(jpa.getLastLoginAt());
        return user;
    }
}
