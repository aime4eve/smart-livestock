package com.smartlivestock.identity.infrastructure.acl;

import com.smartlivestock.commerce.application.dto.ContractResponse;
import com.smartlivestock.commerce.application.query.SubscriptionQueryService;
import com.smartlivestock.identity.domain.port.CommerceQueryPort;
import com.smartlivestock.identity.domain.port.dto.ContractDto;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component("identityCommerceQueryPort")
public class CommerceQueryPortImpl implements CommerceQueryPort {

    private final SubscriptionQueryService subscriptionQueryService;

    public CommerceQueryPortImpl(SubscriptionQueryService subscriptionQueryService) {
        this.subscriptionQueryService = subscriptionQueryService;
    }

    @Override
    public Optional<ContractDto> findActiveContractByTenantId(Long tenantId) {
        try {
            return subscriptionQueryService.findContractByTenantId(tenantId)
                    .map(c -> new ContractDto(c.getId(), c.getTenantId(), c.getContractNumber(),
                            c.getRevenueShareRatio(), c.getStartedAt(), c.getExpiresAt(), c.getStatus()));
        } catch (Exception e) {
            return Optional.empty();
        }
    }
}
