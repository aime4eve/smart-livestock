package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;

import java.util.List;
import java.util.Optional;

public interface UserFarmAssignmentRepository {
    boolean existsByUserIdAndFarmId(Long userId, Long farmId);
    void save(Long userId, Long farmId, String role, String status);
    void updateStatus(Long userId, Long farmId, String status);
    void updateRoleAndStatus(Long userId, Long farmId, String role, String status);

    List<UserFarmAssignmentJpaEntity> findByFarmIdAndStatus(Long farmId, String status);
    List<UserFarmAssignmentJpaEntity> findByTenantIdAndStatus(Long tenantId, String status);
    long countByFarmIdAndStatus(Long farmId, String status);
    Optional<UserFarmAssignmentJpaEntity> findByFarmIdAndRoleAndStatus(Long farmId, String role, String status);
    Optional<UserFarmAssignmentJpaEntity> findByUserIdAndFarmId(Long userId, Long farmId);
}
