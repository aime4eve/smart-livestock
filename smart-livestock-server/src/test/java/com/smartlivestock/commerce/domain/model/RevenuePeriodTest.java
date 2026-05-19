package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.commerce.domain.model.event.RevenuePartnerConfirmedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenuePeriodCreatedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenuePlatformConfirmedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenueSettledEvent;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.*;

class RevenuePeriodTest {

    private static final Long CONTRACT_ID = 100L;
    private static final Long TENANT_ID = 1L;
    private static final BigDecimal RATIO = new BigDecimal("0.3000");

    // ── Factory helpers ──────────────────────────────────────────────

    private RevenuePeriod createPendingPeriod() {
        LocalDate start = LocalDate.of(2026, 5, 1);
        LocalDate end = LocalDate.of(2026, 5, 31);
        return RevenuePeriod.create(CONTRACT_ID, TENANT_ID, start, end,
            10000, 7000, 3000, RATIO);
    }

    private RevenuePeriod createPlatformConfirmedPeriod() {
        RevenuePeriod period = createPendingPeriod();
        period.confirmByPlatform();
        period.clearDomainEvents();
        return period;
    }

    private RevenuePeriod createPartnerConfirmedPeriod() {
        RevenuePeriod period = createPlatformConfirmedPeriod();
        period.confirmByPartner();
        period.clearDomainEvents();
        return period;
    }

    // ── create ───────────────────────────────────────────────────────

    @Nested
    class Create {

        @Test
        void setsPendingStatusAndFields() {
            LocalDate start = LocalDate.of(2026, 5, 1);
            LocalDate end = LocalDate.of(2026, 5, 31);

            RevenuePeriod period = RevenuePeriod.create(CONTRACT_ID, TENANT_ID,
                start, end, 10000, 7000, 3000, RATIO);

            assertThat(period.getContractId()).isEqualTo(CONTRACT_ID);
            assertThat(period.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(period.getPeriodStart()).isEqualTo(start);
            assertThat(period.getPeriodEnd()).isEqualTo(end);
            assertThat(period.getGrossAmount()).isEqualTo(10000);
            assertThat(period.getPlatformShare()).isEqualTo(7000);
            assertThat(period.getPartnerShare()).isEqualTo(3000);
            assertThat(period.getRevenueShareRatio()).isEqualByComparingTo(RATIO);
            assertThat(period.getStatus()).isEqualTo(RevenueSettlementStatus.PENDING);
            assertThat(period.getSettledAt()).isNull();
        }

        @Test
        void registersRevenuePeriodCreatedEvent() {
            RevenuePeriod period = createPendingPeriod();

            assertThat(period.getDomainEvents()).hasSize(1);
            RevenuePeriodCreatedEvent event = (RevenuePeriodCreatedEvent) period.getDomainEvents().get(0);
            assertThat(event.getContractId()).isEqualTo(CONTRACT_ID);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
        }

        @Test
        void rejectsRatioEqualToZero() {
            LocalDate start = LocalDate.of(2026, 5, 1);
            LocalDate end = LocalDate.of(2026, 5, 31);

            assertThatThrownBy(() -> RevenuePeriod.create(CONTRACT_ID, TENANT_ID,
                start, end, 10000, 10000, 0, BigDecimal.ZERO))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.INVALID_REVENUE_SHARE_RATIO));
        }

        @Test
        void rejectsRatioEqualToOne() {
            LocalDate start = LocalDate.of(2026, 5, 1);
            LocalDate end = LocalDate.of(2026, 5, 31);

            assertThatThrownBy(() -> RevenuePeriod.create(CONTRACT_ID, TENANT_ID,
                start, end, 10000, 0, 10000, BigDecimal.ONE))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.INVALID_REVENUE_SHARE_RATIO));
        }

        @Test
        void rejectsSharesNotSummingToGross() {
            LocalDate start = LocalDate.of(2026, 5, 1);
            LocalDate end = LocalDate.of(2026, 5, 31);

            assertThatThrownBy(() -> RevenuePeriod.create(CONTRACT_ID, TENANT_ID,
                start, end, 10000, 8000, 3000, RATIO))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        }

        @Test
        void rejectsPeriodEndBeforeStart() {
            LocalDate start = LocalDate.of(2026, 5, 31);
            LocalDate end = LocalDate.of(2026, 5, 1);

            assertThatThrownBy(() -> RevenuePeriod.create(CONTRACT_ID, TENANT_ID,
                start, end, 10000, 7000, 3000, RATIO))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        }
    }

    // ── confirmByPlatform ─────────────────────────────────────────────

    @Nested
    class ConfirmByPlatform {

        @Test
        void transitionsToPlatformConfirmed() {
            RevenuePeriod period = createPendingPeriod();
            period.clearDomainEvents();

            period.confirmByPlatform();

            assertThat(period.getStatus()).isEqualTo(RevenueSettlementStatus.PLATFORM_CONFIRMED);
            assertThat(period.getDomainEvents()).hasSize(1);
            assertThat(period.getDomainEvents().get(0)).isInstanceOf(RevenuePlatformConfirmedEvent.class);
        }

        @Test
        void rejectsFromNonPending() {
            RevenuePeriod period = createPlatformConfirmedPeriod();
            assertThatThrownBy(period::confirmByPlatform)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void rejectsFromSettled() {
            RevenuePeriod period = createPartnerConfirmedPeriod();
            period.settle(Instant.now());
            period.clearDomainEvents();

            assertThatThrownBy(period::confirmByPlatform)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── confirmByPartner ──────────────────────────────────────────────

    @Nested
    class ConfirmByPartner {

        @Test
        void transitionsToPartnerConfirmed() {
            RevenuePeriod period = createPlatformConfirmedPeriod();

            period.confirmByPartner();

            assertThat(period.getStatus()).isEqualTo(RevenueSettlementStatus.PARTNER_CONFIRMED);
            assertThat(period.getDomainEvents()).hasSize(1);
            assertThat(period.getDomainEvents().get(0)).isInstanceOf(RevenuePartnerConfirmedEvent.class);
        }

        @Test
        void rejectsFromPending() {
            RevenuePeriod period = createPendingPeriod();
            period.clearDomainEvents();

            assertThatThrownBy(period::confirmByPartner)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void rejectsFromPartnerConfirmed() {
            RevenuePeriod period = createPartnerConfirmedPeriod();
            assertThatThrownBy(period::confirmByPartner)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── settle ────────────────────────────────────────────────────────

    @Nested
    class Settle {

        @Test
        void transitionsToSettled() {
            RevenuePeriod period = createPartnerConfirmedPeriod();
            Instant settledAt = Instant.now();

            period.settle(settledAt);

            assertThat(period.getStatus()).isEqualTo(RevenueSettlementStatus.SETTLED);
            assertThat(period.getSettledAt()).isEqualTo(settledAt);
            assertThat(period.getDomainEvents()).hasSize(1);
            assertThat(period.getDomainEvents().get(0)).isInstanceOf(RevenueSettledEvent.class);
        }

        @Test
        void rejectsFromPending() {
            RevenuePeriod period = createPendingPeriod();
            assertThatThrownBy(() -> period.settle(Instant.now()))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void rejectsFromPlatformConfirmed() {
            RevenuePeriod period = createPlatformConfirmedPeriod();
            assertThatThrownBy(() -> period.settle(Instant.now()))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void rejectsFromSettled() {
            RevenuePeriod period = createPartnerConfirmedPeriod();
            period.settle(Instant.now());
            period.clearDomainEvents();

            assertThatThrownBy(() -> period.settle(Instant.now()))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }
}
