package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataUserFarmAssignmentRepository extends JpaRepository<UserFarmAssignmentJpaEntity, Long> {
}
