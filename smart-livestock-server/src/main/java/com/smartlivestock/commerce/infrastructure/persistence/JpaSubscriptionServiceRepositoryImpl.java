package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.domain.model.SubscriptionService;
import com.smartlivestock.commerce.domain.model.SubscriptionServiceStatus;
import com.smartlivestock.commerce.domain.repository.SubscriptionServiceRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.SubscriptionServiceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaSubscriptionServiceRepositoryImpl implements SubscriptionServiceRepository {

    private final SpringDataSubscriptionServiceRepository springDataRepo;

    @Override
    public Optional<SubscriptionService> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId)
                .map(SubscriptionServiceMapper::toDomain);
    }

    @Override
    public Optional<SubscriptionService> findById(Long id) {
        return springDataRepo.findById(id)
                .map(SubscriptionServiceMapper::toDomain);
    }

    @Override
    public List<SubscriptionService> findByStatus(SubscriptionServiceStatus status) {
        return springDataRepo.findByStatus(EnumConverters.toDb(status)).stream()
                .map(SubscriptionServiceMapper::toDomain)
                .toList();
    }

    @Override
    public SubscriptionService save(SubscriptionService subscriptionService) {
        if (subscriptionService.getId() != null) {
            return springDataRepo.findById(subscriptionService.getId())
                    .map(existing -> {
                        SubscriptionServiceMapper.updateEntity(existing, subscriptionService);
                        return SubscriptionServiceMapper.toDomain(springDataRepo.save(existing));
                    })
                    .orElseGet(() -> SubscriptionServiceMapper.toDomain(springDataRepo.save(
                            SubscriptionServiceMapper.toJpaEntity(subscriptionService))));
        }
        return SubscriptionServiceMapper.toDomain(springDataRepo.save(
                SubscriptionServiceMapper.toJpaEntity(subscriptionService)));
    }
}
