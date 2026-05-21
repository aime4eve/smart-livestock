package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.domain.repository.port.SubscriptionQueryPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaSubscriptionQueryPortImpl implements SubscriptionQueryPort {

    private final SpringDataSubscriptionRepository springDataRepo;

    @Override
    public Optional<String> findSubscriptionStatusByTenantId(Long tenantId) {
        return springDataRepo.findStatusByTenantId(tenantId);
    }
}
