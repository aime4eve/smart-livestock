package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.UserJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataUserRepository extends JpaRepository<UserJpaEntity, Long> {
    Optional<UserJpaEntity> findByPhone(String phone);

    /** Case-insensitive account/email match, phone exact (normalized upstream). */
    @org.springframework.data.jpa.repository.Query(
            "SELECT u FROM UserJpaEntity u WHERE " +
            "LOWER(u.account) = LOWER(:identifier) OR LOWER(u.email) = LOWER(:identifier) " +
            "OR u.phone = :identifier")
    Optional<UserJpaEntity> findByLoginIdentifier(@org.springframework.data.repository.query.Param("identifier") String identifier);
    List<UserJpaEntity> findByTenantId(Long tenantId);
    boolean existsByRoleAndIsActive(String role, boolean isActive);
}
