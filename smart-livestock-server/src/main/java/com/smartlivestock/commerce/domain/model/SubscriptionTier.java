package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;

import java.util.List;

/**
 * Subscription tiers with USD per-head-per-month pricing banded by herd size.
 * <p>
 * Pricing decision 2026-09-23 (NIX-245): global USD quotation; hardware is
 * sold separately as a one-time customer-owned purchase; the subscription is
 * billed per head per month with herd-size bands. BASIC stays free with a
 * 50-head cap (enforced via feature_gates). ENTERPRISE keeps custom contract
 * pricing. All amounts are US cents.
 */
public enum SubscriptionTier {

    BASIC(List.of(PriceBand.of(1, PriceBand.UNBOUNDED, 0)), 50),
    STANDARD(List.of(
            PriceBand.of(1, 99, 260),
            PriceBand.of(100, 499, 215),
            PriceBand.of(500, PriceBand.UNBOUNDED, 140)), -1),
    PREMIUM(List.of(
            PriceBand.of(1, 99, 320),
            PriceBand.of(100, 499, 265),
            PriceBand.of(500, PriceBand.UNBOUNDED, 175)), -1),
    ENTERPRISE(List.of(), -1);

    /** -1 means no herd-size cap (cap is a quota concept, mirrored in feature_gates). */
    private final int livestockCap;
    private final List<PriceBand> priceBands;

    SubscriptionTier(List<PriceBand> priceBands, int livestockCap) {
        this.priceBands = priceBands;
        this.livestockCap = livestockCap;
    }

    public List<PriceBand> getPriceBands() { return priceBands; }

    public int getLivestockCap() { return livestockCap; }

    /**
     * Price band applicable to the given head count. Head counts below the
     * lowest band (including 0) resolve to the first band — the fee formula
     * naturally yields 0 for an empty herd.
     */
    public PriceBand bandFor(int livestockCount) {
        return priceBands.stream()
                .filter(b -> b.covers(livestockCount))
                .findFirst()
                .orElse(priceBands.get(0));
    }

    /**
     * Monthly subscription fee in US cents: head count × applicable band unit price.
     */
    public int calculateMonthlyFee(int livestockCount) {
        if (this == ENTERPRISE)
            throw new DomainException(ErrorCode.ENTERPRISE_CUSTOM_PRICING,
                "Enterprise 需定制计费，不可自动计算");
        return bandFor(livestockCount).unitPriceUsdCents() * livestockCount;
    }

    /**
     * Herd-size pricing band; maxHead = -1 means unbounded.
     */
    public record PriceBand(int minHead, int maxHead, int unitPriceUsdCents) {

        public static final int UNBOUNDED = -1;

        public static PriceBand of(int minHead, int maxHead, int unitPriceUsdCents) {
            return new PriceBand(minHead, maxHead, unitPriceUsdCents);
        }

        public boolean covers(int headCount) {
            return headCount >= minHead && (maxHead == UNBOUNDED || headCount <= maxHead);
        }
    }
}
