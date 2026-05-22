package com.smartlivestock.commerce.domain.model;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class FeatureGateTest {

    @Nested
    class GateTypeNone {

        @Test
        void unrestricted_allowsAccess() {
            FeatureGate gate = new FeatureGate("standard", "alert_management", GateType.NONE, null, null, true);

            assertThat(gate.getGateType()).isEqualTo(GateType.NONE);
        }
    }

    @Nested
    class GateTypeLock {

        @Test
        void isLockedWhenEnabled() {
            FeatureGate gate = new FeatureGate("basic", "advanced_analytics", GateType.LOCK, null, null, true);

            assertThat(gate.getGateType()).isEqualTo(GateType.LOCK);
            assertThat(gate.isEnabled()).isTrue();
        }

        @Test
        void isLockedWhenDisabled() {
            FeatureGate gate = new FeatureGate("basic", "alert_management", GateType.LOCK, null, null, false);

            assertThat(gate.getGateType()).isEqualTo(GateType.LOCK);
            assertThat(gate.isEnabled()).isFalse();
        }
    }

    @Nested
    class GateTypeLimit {

        @Test
        void isLimitedWithLimitValue() {
            FeatureGate gate = new FeatureGate("basic", "livestock_management", GateType.LIMIT, 50, null, true);

            assertThat(gate.getGateType()).isEqualTo(GateType.LIMIT);
            assertThat(gate.getLimitValue()).isEqualTo(50);
        }

        @Test
        void isLimitedWithNullRetentionDays() {
            FeatureGate gate = new FeatureGate("standard", "fence_management", GateType.LIMIT, 20, null, true);

            assertThat(gate.getRetentionDays()).isNull();
        }
    }

    @Nested
    class GateTypeFilter {

        @Test
        void isFilteredWithRetentionDays() {
            FeatureGate gate = new FeatureGate("standard", "advanced_analytics", GateType.FILTER, null, 30, true);

            assertThat(gate.getGateType()).isEqualTo(GateType.FILTER);
            assertThat(gate.getRetentionDays()).isEqualTo(30);
        }
    }

    @Nested
    class UnrestrictedFactory {

        @Test
        void createsNoneGate() {
            FeatureGate gate = FeatureGate.unrestricted();

            assertThat(gate.getGateType()).isEqualTo(GateType.NONE);
        }
    }
}
