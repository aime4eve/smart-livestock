package com.smartlivestock.commerce.domain.model;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class FeatureGateTest {

    @Nested
    class GateTypeNone {

        @Test
        void allowsUnrestricted() {
            FeatureGate gate = new FeatureGate("standard", "alert_management", "none", null, null, true);

            assertThat(gate.allowsUnrestricted()).isTrue();
            assertThat(gate.isLocked()).isFalse();
            assertThat(gate.isLimited()).isFalse();
            assertThat(gate.isFiltered()).isFalse();
        }
    }

    @Nested
    class GateTypeLock {

        @Test
        void isLockedWhenEnabled() {
            FeatureGate gate = new FeatureGate("basic", "advanced_analytics", "lock", null, null, true);

            assertThat(gate.isLocked()).isTrue();
            assertThat(gate.isEnabled()).isTrue();
        }

        @Test
        void isLockedWhenDisabled() {
            FeatureGate gate = new FeatureGate("basic", "alert_management", "lock", null, null, false);

            assertThat(gate.isLocked()).isTrue();
            assertThat(gate.isEnabled()).isFalse();
        }
    }

    @Nested
    class GateTypeLimit {

        @Test
        void isLimitedWithLimitValue() {
            FeatureGate gate = new FeatureGate("basic", "livestock_management", "limit", 50, null, true);

            assertThat(gate.isLimited()).isTrue();
            assertThat(gate.getLimitValue()).isEqualTo(50);
            assertThat(gate.isEnabled()).isTrue();
        }

        @Test
        void isLimitedWithNullRetentionDays() {
            FeatureGate gate = new FeatureGate("standard", "fence_management", "limit", 20, null, true);

            assertThat(gate.isLimited()).isTrue();
            assertThat(gate.getRetentionDays()).isNull();
        }
    }

    @Nested
    class GateTypeFilter {

        @Test
        void isFilteredWithRetentionDays() {
            FeatureGate gate = new FeatureGate("standard", "advanced_analytics", "filter", null, 30, true);

            assertThat(gate.isFiltered()).isTrue();
            assertThat(gate.getRetentionDays()).isEqualTo(30);
        }
    }

    @Nested
    class FieldAccess {

        @Test
        void hasAllFields() {
            FeatureGate gate = new FeatureGate("premium", "api_access", "none", null, null, true);
            gate.setId(1L);

            assertThat(gate.getId()).isEqualTo(1L);
            assertThat(gate.getTier()).isEqualTo("premium");
            assertThat(gate.getFeatureKey()).isEqualTo("api_access");
            assertThat(gate.getGateType()).isEqualTo("none");
            assertThat(gate.getLimitValue()).isNull();
            assertThat(gate.getRetentionDays()).isNull();
            assertThat(gate.isEnabled()).isTrue();
        }

        @Test
        void settersWork() {
            FeatureGate gate = new FeatureGate();
            gate.setTier("enterprise");
            gate.setFeatureKey("worker_management");
            gate.setGateType("none");
            gate.setLimitValue(100);
            gate.setRetentionDays(60);
            gate.setEnabled(false);

            assertThat(gate.getTier()).isEqualTo("enterprise");
            assertThat(gate.getFeatureKey()).isEqualTo("worker_management");
            assertThat(gate.getGateType()).isEqualTo("none");
            assertThat(gate.getLimitValue()).isEqualTo(100);
            assertThat(gate.getRetentionDays()).isEqualTo(60);
            assertThat(gate.isEnabled()).isFalse();
        }
    }
}
