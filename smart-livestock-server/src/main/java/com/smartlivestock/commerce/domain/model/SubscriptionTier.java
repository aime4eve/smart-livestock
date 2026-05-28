package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;

public enum SubscriptionTier {
    BASIC(0, 50, 40),
    STANDARD(1400, 200, 30),
    PREMIUM(2800, 1000, 15),
    ENTERPRISE(-1, -1, -1);

    private final int monthlyPriceCents;
    private final int includedLivestock;
    private final int overagePriceCents;

    SubscriptionTier(int monthlyPriceCents, int includedLivestock, int overagePriceCents) {
        this.monthlyPriceCents = monthlyPriceCents;
        this.includedLivestock = includedLivestock;
        this.overagePriceCents = overagePriceCents;
    }

    public int getMonthlyPriceCents() { return monthlyPriceCents; }
    public int getIncludedLivestock() { return includedLivestock; }
    public int getOveragePriceCents() { return overagePriceCents; }

    public int calculateMonthlyFee(int livestockCount) {
        if (this == ENTERPRISE)
            throw new DomainException(ErrorCode.ENTERPRISE_CUSTOM_PRICING,
                "Enterprise 需定制计费，不可自动计算");
        int base = monthlyPriceCents;
        int overflow = Math.max(0, livestockCount - includedLivestock);
        return base + overflow * overagePriceCents;
    }
}
