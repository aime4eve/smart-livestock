package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
@RequiredArgsConstructor
public class JpaUserFarmAssignmentRepositoryImpl implements UserFarmAssignmentRepository {

    private final SpringDataUserFarmAssignmentRepository springDataRepo;

    @Override
    public boolean existsByUserIdAndFarmId(Long userId, Long farmId) {
        return springDataRepo.existsByUserIdAndFarmId(userId, farmId);
    }

    @Override
    public void save(Long userId, Long farmId, String role, String status) {
        UserFarmAssignmentJpaEntity entity = new UserFarmAssignmentJpaEntity();
        entity.setUserId(userId);
        entity.setFarmId(farmId);
        entity.setRole(role);
        entity.setStatus(status);
        springDataRepo.save(entity);
    }

    @Override
    @Transactional
    public void updateStatus(Long userId, Long farmId, String status) {
        springDataRepo.updateStatus(userId, farmId, status);
    }
}
