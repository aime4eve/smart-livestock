package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.infrastructure.persistence.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaUserRepositoryImpl implements UserRepository {

    private final SpringDataUserRepository springDataRepo;

    @Override
    public User save(User user) {
        return UserMapper.toDomain(springDataRepo.save(UserMapper.toJpaEntity(user)));
    }

    @Override
    public Optional<User> findById(Long id) {
        return springDataRepo.findById(id).map(UserMapper::toDomain);
    }

    @Override
    public Optional<User> findByPhone(String phone) {
        return springDataRepo.findByPhone(phone).map(UserMapper::toDomain);
    }

    @Override
    public List<User> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId).stream()
                .map(UserMapper::toDomain)
                .toList();
    }
}
