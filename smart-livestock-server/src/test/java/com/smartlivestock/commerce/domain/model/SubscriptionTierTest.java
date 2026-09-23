package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

/**
 * NIX-245 USD per-head-per-month pricing: STANDARD $2.60/$2.15/$1.40,
 * PREMIUM $3.20/$2.65/$1.75 per head per month for <100 / 100-499 / >=500
 * head herds (unit prices in US cents: 260/215/140 and 320/265/175).
 */
class SubscriptionTierTest {

    @Nested
    class PriceBands {
        @Test
        void basicIsFreeWithCap() {
            assertThat(SubscriptionTier.BASIC.getPriceBands())
                .singleElement()
                .satisfies(band -> {
                    assertThat(band.unitPriceUsdCents()).isZero();
                    assertThat(band.maxHead()).isEqualTo(SubscriptionTier.PriceBand.UNBOUNDED);
                });
            assertThat(SubscriptionTier.BASIC.getLivestockCap()).isEqualTo(50);
        }

        @Test
        void standardBands() {
            assertThat(SubscriptionTier.STANDARD.getPriceBands())
                .extracting(SubscriptionTier.PriceBand::unitPriceUsdCents)
                .containsExactly(260, 215, 140);
            assertThat(SubscriptionTier.STANDARD.getLivestockCap()).isEqualTo(-1);
        }

        @Test
        void premiumBands() {
            assertThat(SubscriptionTier.PREMIUM.getPriceBands())
                .extracting(SubscriptionTier.PriceBand::unitPriceUsdCents)
                .containsExactly(320, 265, 175);
            assertThat(SubscriptionTier.PREMIUM.getLivestockCap()).isEqualTo(-1);
        }

        @Test
        void enterpriseHasNoBands() {
            assertThat(SubscriptionTier.ENTERPRISE.getPriceBands()).isEmpty();
        }

        @Test
        void bandBoundariesAreInclusive() {
            assertThat(SubscriptionTier.STANDARD.bandFor(99).unitPriceUsdCents()).isEqualTo(260);
            assertThat(SubscriptionTier.STANDARD.bandFor(100).unitPriceUsdCents()).isEqualTo(215);
            assertThat(SubscriptionTier.STANDARD.bandFor(499).unitPriceUsdCents()).isEqualTo(215);
            assertThat(SubscriptionTier.STANDARD.bandFor(500).unitPriceUsdCents()).isEqualTo(140);
            assertThat(SubscriptionTier.PREMIUM.bandFor(1200).maxHead())
                .isEqualTo(SubscriptionTier.PriceBand.UNBOUNDED);
        }

        @Test
        void headCountBelowLowestBandFallsBackToFirstBand() {
            assertThat(SubscriptionTier.STANDARD.bandFor(0).unitPriceUsdCents()).isEqualTo(260);
        }
    }

    @Nested
    class CalculateMonthlyFee {
        @Test
        void zeroHeadsCostsNothing() {
            assertThat(SubscriptionTier.STANDARD.calculateMonthlyFee(0)).isZero();
            assertThat(SubscriptionTier.PREMIUM.calculateMonthlyFee(0)).isZero();
        }

        @Test
        void smallHerd() {
            // 80 × $2.60 = $208.00
            assertThat(SubscriptionTier.STANDARD.calculateMonthlyFee(80)).isEqualTo(20_800);
            // 80 × $3.20 = $256.00
            assertThat(SubscriptionTier.PREMIUM.calculateMonthlyFee(80)).isEqualTo(25_600);
        }

        @Test
        void danishMainstreamHerd() {
            // 260 × $2.15 = $559.00 / 260 × $2.65 = $689.00
            assertThat(SubscriptionTier.STANDARD.calculateMonthlyFee(260)).isEqualTo(55_900);
            assertThat(SubscriptionTier.PREMIUM.calculateMonthlyFee(260)).isEqualTo(68_900);
        }

        @Test
        void largeHerd() {
            // 1000 × $1.40 = $1,400.00 / 1000 × $1.75 = $1,750.00
            assertThat(SubscriptionTier.STANDARD.calculateMonthlyFee(1000)).isEqualTo(140_000);
            assertThat(SubscriptionTier.PREMIUM.calculateMonthlyFee(1000)).isEqualTo(175_000);
        }

        @Test
        void basicIsAlwaysFree() {
            assertThat(SubscriptionTier.BASIC.calculateMonthlyFee(0)).isZero();
            assertThat(SubscriptionTier.BASIC.calculateMonthlyFee(50)).isZero();
        }

        @Test
        void enterpriseThrowsDomainException() {
            DomainException ex = catchThrowableOfType(
                () -> SubscriptionTier.ENTERPRISE.calculateMonthlyFee(100),
                DomainException.class
            );
            assertThat(ex.getCode()).isEqualTo(ErrorCode.ENTERPRISE_CUSTOM_PRICING);
        }
    }
}
