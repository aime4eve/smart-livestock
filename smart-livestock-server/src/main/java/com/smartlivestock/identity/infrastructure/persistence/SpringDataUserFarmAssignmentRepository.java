package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SpringDataUserFarmAssignmentRepository extends JpaRepository<UserFarmAssignmentJpaEntity, Long> {
    boolean existsByUserIdAndFarmId(Long userId, Long farmId);

    @Modifying
    @Query("UPDATE UserFarmAssignmentJpaEntity u SET u.status = :status WHERE u.userId = :userId AND u.farmId = :farmId")
    void updateStatus(@Param("userId") Long userId, @Param("farmId") Long farmId, @Param("status") String status);
}
