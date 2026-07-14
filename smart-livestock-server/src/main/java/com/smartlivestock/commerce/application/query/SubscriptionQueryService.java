package com.smartlivestock.commerce.application.query;

import com.smartlivestock.commerce.application.assembler.ContractAssembler;
import com.smartlivestock.commerce.application.assembler.SubscriptionAssembler;
import com.smartlivestock.commerce.application.dto.ContractResponse;
import com.smartlivestock.commerce.application.dto.SubscriptionResponse;
import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.GateType;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.repository.ContractRepository;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Read-only query service for subscription and contract read models.
 * <p>
 * Handles GET endpoints. No event publishing. Filter-type gate retention
 * days are resolved here, not in ApplicationService.
 */
@Service
public class SubscriptionQueryService {

    private final SubscriptionRepository subscriptionRepository;
    private final ContractRepository contractRepository;
    private final FeatureGateRepository featureGateRepository;
    private final LivestockRepository livestockRepository;

    public SubscriptionQueryService(SubscriptionRepository subscriptionRepository,
                                    ContractRepository contractRepository,
                                    FeatureGateRepository featureGateRepository,
                                    LivestockRepository livestockRepository) {
        this.subscriptionRepository = subscriptionRepository;
        this.contractRepository = contractRepository;
        this.featureGateRepository = featureGateRepository;
        this.livestockRepository = livestockRepository;
    }

    /**
     * Get subscription response for a tenant.
     */
    public Optional<SubscriptionResponse> findByTenantId(Long tenantId) {
        return subscriptionRepository.findByTenantId(tenantId)
            .map(sub -> {
                long livestockCount = livestockRepository.countByTenantId(tenantId);
                return SubscriptionAssembler.toResponse(sub, livestockCount);
            });
    }

    /**
     * Get the effective retention days for a feature key on a tenant's subscription.
     * <p>
     * Filter-type gate: returns retentionDays from the gate.
     * Other gate types or missing subscription: returns empty.
     */
    public Optional<Integer> getRetentionDays(Long tenantId, String featureKey) {
        return subscriptionRepository.findByTenantId(tenantId)
            .filter(Subscription::isActiveOrTrial)
            .flatMap(sub -> featureGateRepository.findByTierAndFeatureKey(
                sub.effectiveTier().name().toLowerCase(), featureKey))
            .filter(gate -> gate.getGateType() == GateType.FILTER)
            .map(FeatureGate::getRetentionDays);
    }

    /**
     * Get contract for the tenant (partner's view).
     */
    public Optional<ContractResponse> findContractByTenantId(Long tenantId) {
        return contractRepository.findByTenantId(tenantId)
            .map(ContractAssembler::toResponse);
    }

    /**
     * Get contract by ID (admin view).
     */
    public Optional<ContractResponse> findContractById(Long id) {
        return contractRepository.findById(id)
            .map(ContractAssembler::toResponse);
    }
}
