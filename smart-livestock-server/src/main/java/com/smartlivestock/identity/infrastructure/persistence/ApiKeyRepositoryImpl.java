package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.identity.domain.repository.ApiKeyRepository;
import com.smartlivestock.identity.infrastructure.persistence.mapper.ApiKeyMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class ApiKeyRepositoryImpl implements ApiKeyRepository {
    private final SpringDataApiKeyRepository springDataRepo;

    @Override
    public ApiKey save(ApiKey apiKey) {
        return ApiKeyMapper.toDomain(springDataRepo.save(ApiKeyMapper.toJpaEntity(apiKey)));
    }
    @Override
    public Optional<ApiKey> findById(Long id) {
        return springDataRepo.findById(id).map(ApiKeyMapper::toDomain);
    }
    @Override
    public Optional<ApiKey> findByKeyHash(String keyHash) {
        return springDataRepo.findByKeyHash(keyHash).map(ApiKeyMapper::toDomain);
    }
    @Override
    public List<ApiKey> findAll() {
        return springDataRepo.findAll().stream().map(ApiKeyMapper::toDomain).toList();
    }
    @Override
    public List<ApiKey> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId).stream().map(ApiKeyMapper::toDomain).toList();
    }
    @Override
    public void deleteById(Long id) {
        springDataRepo.deleteById(id);
    }
}
