package com.smartlivestock.commerce.infrastructure.persistence.mapper;

import com.smartlivestock.commerce.domain.model.*;
import com.smartlivestock.commerce.infrastructure.persistence.entity.*;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class MapperRoundTripTest {

    @Nested
    class SubscriptionRoundTrip {

        @Test
        void allFieldsPreservedViaToJpaEntityAndBack() {
            Subscription original = Subscription.startTrial(
                42L, "revenue_share", Instant.parse("2026-01-01T00:00:00Z"),
                Instant.parse("2026-01-15T00:00:00Z"));
            original.setId(1L);

            SubscriptionJpaEntity jpa = SubscriptionMapper.toJpaEntity(original);
            SubscriptionJpaEntity persisted = simulatePersist(jpa);

            Subscription restored = SubscriptionMapper.toDomain(persisted);

            assertThat(restored.getId()).isEqualTo(1L);
            assertThat(restored.getTenantId()).isEqualTo(42L);
            assertThat(restored.getTier()).isEqualTo(SubscriptionTier.BASIC);
            assertThat(restored.getBillingModel()).isEqualTo("revenue_share");
            assertThat(restored.getStatus()).isEqualTo(SubscriptionStatus.TRIAL);
            assertThat(restored.getBillingCycle()).isNull();
            assertThat(restored.getStartedAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
            assertThat(restored.getTrialEndsAt()).isEqualTo(Instant.parse("2026-01-15T00:00:00Z"));
            assertThat(restored.getExpiresAt()).isNull();
            assertThat(restored.getCancelledAt()).isNull();
        }

        @Test
        void activeSubscriptionWithAllFieldsFilledRoundTrips() {
            Subscription original = Subscription.startTrial(
                1L, "direct", Instant.now(), Instant.now().plusSeconds(86400));
            original.activate(SubscriptionTier.PREMIUM, "yearly",
                Instant.now().plusSeconds(365 * 86400));
            original.setId(99L);

            SubscriptionJpaEntity jpa = SubscriptionMapper.toJpaEntity(original);
            Subscription restored = SubscriptionMapper.toDomain(simulatePersist(jpa));

            assertThat(restored.getTier()).isEqualTo(SubscriptionTier.PREMIUM);
            assertThat(restored.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(restored.getBillingCycle()).isEqualTo("yearly");
            assertThat(restored.getExpiresAt()).isNotNull();
        }

        @Test
        void updateEntityPreservesMutableFields() {
            Subscription original = Subscription.startTrial(
                1L, "direct", Instant.now(), Instant.now().plusSeconds(86400));
            original.activate(SubscriptionTier.STANDARD, "monthly",
                Instant.now().plusSeconds(30 * 86400));
            original.setId(10L);

            SubscriptionJpaEntity existing = new SubscriptionJpaEntity();
            existing.setId(10L);
            existing.setTenantId(1L);

            SubscriptionMapper.updateEntity(existing, original);

            assertThat(existing.getId()).isEqualTo(10L);
            assertThat(existing.getTenantId()).isEqualTo(1L);
            assertThat(existing.getTier()).isEqualTo("standard");
            assertThat(existing.getStatus()).isEqualTo("active");
        }
    }

    @Nested
    class ContractRoundTrip {

        @Test
        void allFieldsPreservedViaToJpaEntityAndBack() {
            Contract original = Contract.create(10L, "CTR-2026-001", "revenue_share",
                "premium", new BigDecimal("0.3000"),
                Instant.parse("2026-01-01T00:00:00Z"));
            original.setId(5L);
            original.sign(100L, Instant.parse("2026-01-02T00:00:00Z"));

            ContractJpaEntity jpa = ContractMapper.toJpaEntity(original);
            ContractJpaEntity persisted = simulatePersist(jpa);

            Contract restored = ContractMapper.toDomain(persisted);

            assertThat(restored.getId()).isEqualTo(5L);
            assertThat(restored.getTenantId()).isEqualTo(10L);
            assertThat(restored.getContractNumber()).isEqualTo("CTR-2026-001");
            assertThat(restored.getBillingModel()).isEqualTo("revenue_share");
            assertThat(restored.getEffectiveTier()).isEqualTo("premium");
            assertThat(restored.getRevenueShareRatio()).isEqualByComparingTo(new BigDecimal("0.3000"));
            assertThat(restored.getStatus()).isEqualTo(ContractStatus.ACTIVE);
            assertThat(restored.getSignedBy()).isEqualTo(100L);
            assertThat(restored.getSignedAt()).isEqualTo(Instant.parse("2026-01-02T00:00:00Z"));
            assertThat(restored.getStartedAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
            assertThat(restored.getExpiresAt()).isNull();
        }

        @Test
        void draftContractRoundTrips() {
            Contract original = Contract.create(1L, "CTR-DRAFT", "direct",
                "basic", null, Instant.now());
            original.setId(2L);

            ContractJpaEntity jpa = ContractMapper.toJpaEntity(original);
            Contract restored = ContractMapper.toDomain(simulatePersist(jpa));

            assertThat(restored.getStatus()).isEqualTo(ContractStatus.DRAFT);
            assertThat(restored.getRevenueShareRatio()).isNull();
            assertThat(restored.getSignedBy()).isNull();
        }
    }

    @Nested
    class RevenuePeriodRoundTrip {

        @Test
        void allFieldsPreservedViaToJpaEntityAndBack() {
            RevenuePeriod original = RevenuePeriod.create(
                5L, 10L,
                LocalDate.of(2026, 1, 1), LocalDate.of(2026, 1, 31),
                10000, 7000, 3000,
                new BigDecimal("0.3000"));
            original.setId(20L);

            RevenuePeriodJpaEntity jpa = RevenuePeriodMapper.toJpaEntity(original);
            RevenuePeriodJpaEntity persisted = simulatePersist(jpa);

            RevenuePeriod restored = RevenuePeriodMapper.toDomain(persisted);

            assertThat(restored.getId()).isEqualTo(20L);
            assertThat(restored.getContractId()).isEqualTo(5L);
            assertThat(restored.getTenantId()).isEqualTo(10L);
            assertThat(restored.getPeriodStart()).isEqualTo(LocalDate.of(2026, 1, 1));
            assertThat(restored.getPeriodEnd()).isEqualTo(LocalDate.of(2026, 1, 31));
            assertThat(restored.getGrossAmount()).isEqualTo(10000);
            assertThat(restored.getPlatformShare()).isEqualTo(7000);
            assertThat(restored.getPartnerShare()).isEqualTo(3000);
            assertThat(restored.getRevenueShareRatio()).isEqualByComparingTo(new BigDecimal("0.3000"));
            assertThat(restored.getStatus()).isEqualTo(RevenueSettlementStatus.PENDING);
            assertThat(restored.getSettledAt()).isNull();
        }

        @Test
        void settledPeriodRoundTrips() {
            RevenuePeriod original = RevenuePeriod.create(
                1L, 2L, LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31),
                5000, 3500, 1500, new BigDecimal("0.3000"));
            original.setId(30L);
            original.confirmByPlatform();
            original.confirmByPartner();
            original.settle(Instant.parse("2026-04-01T00:00:00Z"));

            RevenuePeriodJpaEntity jpa = RevenuePeriodMapper.toJpaEntity(original);
            RevenuePeriod restored = RevenuePeriodMapper.toDomain(simulatePersist(jpa));

            assertThat(restored.getStatus()).isEqualTo(RevenueSettlementStatus.SETTLED);
            assertThat(restored.getSettledAt()).isEqualTo(Instant.parse("2026-04-01T00:00:00Z"));
        }
    }

    @Nested
    class SubscriptionServiceRoundTrip {

        @Test
        void allFieldsPreservedViaToJpaEntityAndBack() {
            SubscriptionService original = SubscriptionService.provision(
                10L, "gps-tracking", "raw-key-abc",
                SubscriptionTier.STANDARD, 200);
            original.setId(50L);

            SubscriptionServiceJpaEntity jpa = SubscriptionServiceMapper.toJpaEntity(original);
            SubscriptionServiceJpaEntity persisted = simulatePersist(jpa);

            SubscriptionService restored = SubscriptionServiceMapper.toDomain(persisted);

            assertThat(restored.getId()).isEqualTo(50L);
            assertThat(restored.getTenantId()).isEqualTo(10L);
            assertThat(restored.getServiceName()).isEqualTo("gps-tracking");
            assertThat(restored.getServiceKeyPrefix()).isEqualTo(original.getServiceKeyPrefix());
            assertThat(restored.getServiceKeyHash()).isEqualTo(original.getServiceKeyHash());
            assertThat(restored.getEffectiveTier()).isEqualTo("standard");
            assertThat(restored.getDeviceQuota()).isEqualTo(200);
            assertThat(restored.getStatus()).isEqualTo(SubscriptionServiceStatus.PROVISIONED);
            assertThat(restored.getHeartbeatIntervalHrs()).isEqualTo(24);
            assertThat(restored.getGracePeriodDays()).isEqualTo(7);
        }

        @Test
        void activatedServiceRoundTrips() {
            SubscriptionService original = SubscriptionService.provision(
                1L, "health-monitor", "key-xyz",
                SubscriptionTier.PREMIUM, 500);
            original.setId(51L);
            original.activate(Instant.now().plusSeconds(365 * 86400));

            SubscriptionServiceJpaEntity jpa = SubscriptionServiceMapper.toJpaEntity(original);
            SubscriptionService restored = SubscriptionServiceMapper.toDomain(simulatePersist(jpa));

            assertThat(restored.getStatus()).isEqualTo(SubscriptionServiceStatus.ACTIVE);
            assertThat(restored.getLastHeartbeatAt()).isNotNull();
            assertThat(restored.getExpiresAt()).isNotNull();
        }

        @Test
        void nullHeartbeatDefaultsPreserved() {
            SubscriptionServiceJpaEntity jpa = new SubscriptionServiceJpaEntity();
            jpa.setId(1L);
            jpa.setTenantId(1L);
            jpa.setServiceName("test");
            jpa.setServiceKeyHash("abc123");
            jpa.setEffectiveTier("basic");
            jpa.setStatus("provisioned");
            jpa.setStartedAt(Instant.now());
            jpa.setHeartbeatIntervalHrs(null);
            jpa.setGracePeriodDays(null);

            SubscriptionService restored = SubscriptionServiceMapper.toDomain(jpa);

            assertThat(restored.getHeartbeatIntervalHrs()).isEqualTo(24);
            assertThat(restored.getGracePeriodDays()).isEqualTo(7);
        }
    }

    @Nested
    class FeatureGateRoundTrip {

        @Test
        void limitGateRoundTrips() {
            FeatureGate original = new FeatureGate("standard", "livestock_management",
                GateType.LIMIT, 200, null, true);
            original.setId(100L);

            FeatureGateJpaEntity jpa = FeatureGateMapper.toJpaEntity(original);
            FeatureGateJpaEntity persisted = simulatePersist(jpa);

            FeatureGate restored = FeatureGateMapper.toDomain(persisted);

            assertThat(restored.getId()).isEqualTo(100L);
            assertThat(restored.getTier()).isEqualTo("standard");
            assertThat(restored.getFeatureKey()).isEqualTo("livestock_management");
            assertThat(restored.getGateType()).isEqualTo(GateType.LIMIT);
            assertThat(restored.getLimitValue()).isEqualTo(200);
            assertThat(restored.getRetentionDays()).isNull();
            assertThat(restored.isEnabled()).isTrue();
        }

        @Test
        void filterGateRoundTrips() {
            FeatureGate original = new FeatureGate("premium", "advanced_analytics",
                GateType.FILTER, null, 30, true);
            original.setId(101L);

            FeatureGateJpaEntity jpa = FeatureGateMapper.toJpaEntity(original);
            FeatureGate restored = FeatureGateMapper.toDomain(simulatePersist(jpa));

            assertThat(restored.getGateType()).isEqualTo(GateType.FILTER);
            assertThat(restored.getRetentionDays()).isEqualTo(30);
            assertThat(restored.getLimitValue()).isNull();
        }

        @Test
        void disabledGateRoundTrips() {
            FeatureGate original = new FeatureGate("basic", "api_access",
                GateType.LOCK, null, null, false);
            original.setId(102L);

            FeatureGateJpaEntity jpa = FeatureGateMapper.toJpaEntity(original);
            FeatureGate restored = FeatureGateMapper.toDomain(simulatePersist(jpa));

            assertThat(restored.isEnabled()).isFalse();
        }

        @Test
        void nullIsEnabledDefaultsToTrue() {
            FeatureGateJpaEntity jpa = new FeatureGateJpaEntity();
            jpa.setId(1L);
            jpa.setTier("enterprise");
            jpa.setFeatureKey("health_monitoring");
            jpa.setGateType("none");
            jpa.setIsEnabled(null);

            FeatureGate restored = FeatureGateMapper.toDomain(jpa);

            assertThat(restored.isEnabled()).isTrue();
        }
    }

    private static SubscriptionJpaEntity simulatePersist(SubscriptionJpaEntity jpa) {
        if (jpa.getId() == null) jpa.setId(1L);
        if (jpa.getCreatedAt() == null) jpa.setCreatedAt(Instant.now());
        if (jpa.getUpdatedAt() == null) jpa.setUpdatedAt(Instant.now());
        return jpa;
    }

    private static ContractJpaEntity simulatePersist(ContractJpaEntity jpa) {
        if (jpa.getId() == null) jpa.setId(1L);
        if (jpa.getCreatedAt() == null) jpa.setCreatedAt(Instant.now());
        if (jpa.getUpdatedAt() == null) jpa.setUpdatedAt(Instant.now());
        return jpa;
    }

    private static RevenuePeriodJpaEntity simulatePersist(RevenuePeriodJpaEntity jpa) {
        if (jpa.getId() == null) jpa.setId(1L);
        if (jpa.getCreatedAt() == null) jpa.setCreatedAt(Instant.now());
        return jpa;
    }

    private static SubscriptionServiceJpaEntity simulatePersist(SubscriptionServiceJpaEntity jpa) {
        if (jpa.getId() == null) jpa.setId(1L);
        if (jpa.getCreatedAt() == null) jpa.setCreatedAt(Instant.now());
        if (jpa.getUpdatedAt() == null) jpa.setUpdatedAt(Instant.now());
        return jpa;
    }

    private static FeatureGateJpaEntity simulatePersist(FeatureGateJpaEntity jpa) {
        if (jpa.getId() == null) jpa.setId(1L);
        if (jpa.getCreatedAt() == null) jpa.setCreatedAt(Instant.now());
        return jpa;
    }
}
