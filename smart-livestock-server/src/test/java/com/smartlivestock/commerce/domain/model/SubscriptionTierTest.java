package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class SubscriptionTierTest {

    @Nested
    class Getters {
        @Test
        void basicProperties() {
            assertThat(SubscriptionTier.BASIC.getMonthlyPriceCents()).isEqualTo(0);
            assertThat(SubscriptionTier.BASIC.getIncludedLivestock()).isEqualTo(50);
            assertThat(SubscriptionTier.BASIC.getOveragePriceCents()).isEqualTo(40);
        }

        @Test
        void standardProperties() {
            assertThat(SubscriptionTier.STANDARD.getMonthlyPriceCents()).isEqualTo(1400);
            assertThat(SubscriptionTier.STANDARD.getIncludedLivestock()).isEqualTo(200);
            assertThat(SubscriptionTier.STANDARD.getOveragePriceCents()).isEqualTo(30);
        }

        @Test
        void premiumProperties() {
            assertThat(SubscriptionTier.PREMIUM.getMonthlyPriceCents()).isEqualTo(2800);
            assertThat(SubscriptionTier.PREMIUM.getIncludedLivestock()).isEqualTo(1000);
            assertThat(SubscriptionTier.PREMIUM.getOveragePriceCents()).isEqualTo(15);
        }

        @Test
        void enterpriseProperties() {
            assertThat(SubscriptionTier.ENTERPRISE.getMonthlyPriceCents()).isEqualTo(-1);
            assertThat(SubscriptionTier.ENTERPRISE.getIncludedLivestock()).isEqualTo(-1);
            assertThat(SubscriptionTier.ENTERPRISE.getOveragePriceCents()).isEqualTo(-1);
        }
    }

    @Nested
    class CalculateMonthlyFee {
        @Test
        void basicZeroLivestock() {
            assertThat(SubscriptionTier.BASIC.calculateMonthlyFee(0)).isEqualTo(0);
        }

        @Test
        void basicWithOverage() {
            // 0 + (60 - 50) * 40 = 400
            assertThat(SubscriptionTier.BASIC.calculateMonthlyFee(60)).isEqualTo(400);
        }

        @Test
        void standardWithinIncluded() {
            assertThat(SubscriptionTier.STANDARD.calculateMonthlyFee(150)).isEqualTo(1400);
        }

        @Test
        void standardWithOverage() {
            // 1400 + (250 - 200) * 30 = 2900
            assertThat(SubscriptionTier.STANDARD.calculateMonthlyFee(250)).isEqualTo(2900);
        }

        @Test
        void premiumAtLimit() {
            assertThat(SubscriptionTier.PREMIUM.calculateMonthlyFee(1000)).isEqualTo(2800);
        }

        @Test
        void premiumWithOverage() {
            // 2800 + (1015 - 1000) * 15 = 3025
            assertThat(SubscriptionTier.PREMIUM.calculateMonthlyFee(1015)).isEqualTo(3025);
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
