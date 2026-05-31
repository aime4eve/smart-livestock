package com.smartlivestock.identity.domain.repository;

public interface UserFarmAssignmentRepository {
    boolean existsByUserIdAndFarmId(Long userId, Long farmId);
    void save(Long userId, Long farmId, String role, String status);
    void updateStatus(Long userId, Long farmId, String status);
}
