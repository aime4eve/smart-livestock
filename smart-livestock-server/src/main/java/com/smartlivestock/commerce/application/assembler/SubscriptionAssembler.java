package com.smartlivestock.commerce.application.assembler;

import com.smartlivestock.commerce.application.dto.SubscriptionResponse;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.model.Subscription;

import java.util.List;

/**
 * Maps Subscription domain objects to SubscriptionResponse DTOs.
 */
public final class SubscriptionAssembler {

    private SubscriptionAssembler() {}

    public static SubscriptionResponse toResponse(Subscription domain) {
        SubscriptionResponse dto = new SubscriptionResponse();
        dto.setId(domain.getId());
        dto.setTenantId(domain.getTenantId());
        dto.setTier(domain.getTier() != null ? domain.getTier().name() : null);
        dto.setBillingModel(domain.getBillingModel());
        dto.setStatus(domain.getStatus() != null ? domain.getStatus().name() : null);
        dto.setBillingCycle(domain.getBillingCycle());
        dto.setStartedAt(domain.getStartedAt());
        dto.setExpiresAt(domain.getExpiresAt());
        dto.setTrialEndsAt(domain.getTrialEndsAt());
        dto.setCancelledAt(domain.getCancelledAt());
        dto.setEffectiveTier(domain.effectiveTier() != null ? domain.effectiveTier().name() : null);
        return dto;
    }

    /**
     * Build response enriched with livestock count and USD per-head pricing.
     * All amounts are US cents, derived from SubscriptionTier herd-size bands.
     * Enterprise tier is custom-priced: pricing fields are left null.
     */
    public static SubscriptionResponse toResponse(Subscription domain, long livestockCount) {
        SubscriptionResponse dto = toResponse(domain);
        dto.setLivestockCount((int) livestockCount);

        SubscriptionTier tier = domain.effectiveTier();
        if (tier != null) {
            dto.setLivestockCap(tier.getLivestockCap());
        }
        if (tier != null && tier != SubscriptionTier.ENTERPRISE) {
            SubscriptionTier.PriceBand band = tier.bandFor((int) livestockCount);
            dto.setApplicableBand(band);
            dto.setUnitPriceUsdCents(band.unitPriceUsdCents());
            dto.setMonthlyFeeUsdCents(tier.calculateMonthlyFee((int) livestockCount));
        }
        return dto;
    }

    public static List<SubscriptionResponse> toResponseList(List<Subscription> domains) {
        return domains.stream().map(SubscriptionAssembler::toResponse).toList();
    }
}
