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
     * Build response enriched with livestock count and calculated fees.
     * Fees are in yuan (元), derived from SubscriptionTier pricing (stored in cents).
     * Enterprise tier is custom-priced: fees are left at 0.
     */
    public static SubscriptionResponse toResponse(Subscription domain, long livestockCount) {
        SubscriptionResponse dto = toResponse(domain);
        dto.setLivestockCount((int) livestockCount);

        SubscriptionTier tier = domain.effectiveTier();
        if (tier != null && tier != SubscriptionTier.ENTERPRISE) {
            double tierFee = tier.getMonthlyPriceCents() / 100.0;
            int overflow = (int) Math.max(0, livestockCount - tier.getIncludedLivestock());
            double deviceFee = overflow * tier.getOveragePriceCents() / 100.0;
            dto.setCalculatedTierFee(tierFee);
            dto.setCalculatedDeviceFee(deviceFee);
            dto.setCalculatedTotal(tierFee + deviceFee);
        }
        return dto;
    }

    public static List<SubscriptionResponse> toResponseList(List<Subscription> domains) {
        return domains.stream().map(SubscriptionAssembler::toResponse).toList();
    }
}
