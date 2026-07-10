package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataUserFarmAssignmentRepository extends JpaRepository<UserFarmAssignmentJpaEntity, Long> {
    boolean existsByUserIdAndFarmId(Long userId, Long farmId);
    Optional<UserFarmAssignmentJpaEntity> findByUserIdAndFarmId(Long userId, Long farmId);

    @Modifying
    @Query("UPDATE UserFarmAssignmentJpaEntity u SET u.status = :status WHERE u.userId = :userId AND u.farmId = :farmId")
    void updateStatus(@Param("userId") Long userId, @Param("farmId") Long farmId, @Param("status") String status);

    @Modifying
    @Query("UPDATE UserFarmAssignmentJpaEntity u SET u.role = :role, u.status = :status WHERE u.userId = :userId AND u.farmId = :farmId")
    void updateRoleAndStatus(@Param("userId") Long userId, @Param("farmId") Long farmId, @Param("role") String role, @Param("status") String status);

    List<UserFarmAssignmentJpaEntity> findByFarmIdAndStatus(Long farmId, String status);

    @Query("SELECT u FROM UserFarmAssignmentJpaEntity u JOIN FarmJpaEntity f ON u.farmId = f.id WHERE f.tenantId = :tenantId AND u.status = :status")
    List<UserFarmAssignmentJpaEntity> findByTenantIdAndStatus(@Param("tenantId") Long tenantId, @Param("status") String status);

    long countByFarmIdAndStatus(Long farmId, String status);

    Optional<UserFarmAssignmentJpaEntity> findByFarmIdAndRoleAndStatus(Long farmId, String role, String status);
}
