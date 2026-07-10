package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

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

    @Override
    @Transactional
    public void updateRoleAndStatus(Long userId, Long farmId, String role, String status) {
        springDataRepo.updateRoleAndStatus(userId, farmId, role, status);
    }

    @Override
    public List<UserFarmAssignmentJpaEntity> findByFarmIdAndStatus(Long farmId, String status) {
        return springDataRepo.findByFarmIdAndStatus(farmId, status);
    }

    @Override
    public List<UserFarmAssignmentJpaEntity> findByTenantIdAndStatus(Long tenantId, String status) {
        return springDataRepo.findByTenantIdAndStatus(tenantId, status);
    }

    @Override
    public long countByFarmIdAndStatus(Long farmId, String status) {
        return springDataRepo.countByFarmIdAndStatus(farmId, status);
    }

    @Override
    public Optional<UserFarmAssignmentJpaEntity> findByFarmIdAndRoleAndStatus(Long farmId, String role, String status) {
        return springDataRepo.findByFarmIdAndRoleAndStatus(farmId, role, status);
    }

    @Override
    public Optional<UserFarmAssignmentJpaEntity> findByUserIdAndFarmId(Long userId, Long farmId) {
        return springDataRepo.findByUserIdAndFarmId(userId, farmId);
    }
}
