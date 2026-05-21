package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.SubscriptionMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaSubscriptionRepositoryImpl implements SubscriptionRepository {

    private final SpringDataSubscriptionRepository springDataRepo;

    @Override
    public Optional<Subscription> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId)
                .map(SubscriptionMapper::toDomain);
    }

    @Override
    public List<Subscription> findByStatus(SubscriptionStatus status) {
        return springDataRepo.findByStatus(EnumConverters.toDb(status)).stream()
                .map(SubscriptionMapper::toDomain)
                .toList();
    }

    @Override
    public Subscription save(Subscription subscription) {
        if (subscription.getId() != null) {
            return springDataRepo.findById(subscription.getId())
                    .map(existing -> {
                        SubscriptionMapper.updateEntity(existing, subscription);
                        return SubscriptionMapper.toDomain(springDataRepo.save(existing));
                    })
                    .orElseGet(() -> SubscriptionMapper.toDomain(springDataRepo.save(
                            SubscriptionMapper.toJpaEntity(subscription))));
        }
        return SubscriptionMapper.toDomain(springDataRepo.save(
                SubscriptionMapper.toJpaEntity(subscription)));
    }
}
