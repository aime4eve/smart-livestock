package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.commerce.domain.model.event.ContractCreatedEvent;
import com.smartlivestock.commerce.domain.model.event.ContractExpiredEvent;
import com.smartlivestock.commerce.domain.model.event.ContractReactivatedEvent;
import com.smartlivestock.commerce.domain.model.event.ContractSuspendedEvent;
import com.smartlivestock.commerce.domain.model.event.ContractTerminatedEvent;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.event.ContractSignedEvent;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;

import static org.assertj.core.api.Assertions.*;

class ContractTest {

    private static final Long TENANT_ID = 1L;
    private static final Long USER_ID = 10L;
    private static final String CONTRACT_NUMBER = "CTR-2026-001";

    // ── Factory helpers ──────────────────────────────────────────────

    private Contract createDraftContract() {
        Instant now = Instant.now();
        Instant started = now.plusSeconds(86400);
        return Contract.create(TENANT_ID, CONTRACT_NUMBER, "revenue_share",
            "STANDARD", new BigDecimal("0.3000"), started);
    }

    private Contract createSignedContract() {
        Contract contract = createDraftContract();
        contract.sign(USER_ID);
        contract.clearDomainEvents();
        return contract;
    }

    // ── create ───────────────────────────────────────────────────────

    @Nested
    class Create {

        @Test
        void setsDraftStatusAndFields() {
            Instant now = Instant.now();
            Instant started = now.plusSeconds(86400);
            BigDecimal ratio = new BigDecimal("0.3000");

            Contract contract = Contract.create(TENANT_ID, CONTRACT_NUMBER,
                "revenue_share", "STANDARD", ratio, started);

            assertThat(contract.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(contract.getContractNumber()).isEqualTo(CONTRACT_NUMBER);
            assertThat(contract.getBillingModel()).isEqualTo("revenue_share");
            assertThat(contract.getEffectiveTier()).isEqualTo("STANDARD");
            assertThat(contract.getRevenueShareRatio()).isEqualByComparingTo(ratio);
            assertThat(contract.getStartedAt()).isEqualTo(started);
            assertThat(contract.getStatus()).isEqualTo(ContractStatus.DRAFT);
            assertThat(contract.getSignedBy()).isNull();
            assertThat(contract.getSignedAt()).isNull();
            assertThat(contract.getExpiresAt()).isNull();
        }

        @Test
        void registersContractCreatedEvent() {
            Contract contract = createDraftContract();

            assertThat(contract.getDomainEvents()).hasSize(1);
            ContractCreatedEvent event = (ContractCreatedEvent) contract.getDomainEvents().get(0);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(event.getContractNumber()).isEqualTo(CONTRACT_NUMBER);
        }

        @Test
        void revenueShareModel_requiresRatio() {
            Instant now = Instant.now();
            assertThatThrownBy(() -> Contract.create(TENANT_ID, CONTRACT_NUMBER,
                "revenue_share", "STANDARD", null, now.plusSeconds(86400)))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.INVALID_REVENUE_SHARE_RATIO));
        }

        @Test
        void nonRevenueShareModel_allowsNullRatio() {
            Instant now = Instant.now();
            Contract contract = Contract.create(TENANT_ID, CONTRACT_NUMBER,
                "direct", "STANDARD", null, now.plusSeconds(86400));

            assertThat(contract.getRevenueShareRatio()).isNull();
            assertThat(contract.getStatus()).isEqualTo(ContractStatus.DRAFT);
        }

        @Test
        void ratioMustBeGreaterThanZero() {
            Instant now = Instant.now();
            assertThatThrownBy(() -> Contract.create(TENANT_ID, CONTRACT_NUMBER,
                "revenue_share", "STANDARD", BigDecimal.ZERO, now.plusSeconds(86400)))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.INVALID_REVENUE_SHARE_RATIO));
        }

        @Test
        void ratioMustBeLessThanOne() {
            Instant now = Instant.now();
            assertThatThrownBy(() -> Contract.create(TENANT_ID, CONTRACT_NUMBER,
                "revenue_share", "STANDARD", BigDecimal.ONE, now.plusSeconds(86400)))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.INVALID_REVENUE_SHARE_RATIO));
        }
    }

    // ── sign ─────────────────────────────────────────────────────────

    @Nested
    class Sign {

        @Test
        void transitionsToActive() {
            Contract contract = createDraftContract();
            contract.clearDomainEvents();

            contract.sign(USER_ID);

            assertThat(contract.getStatus()).isEqualTo(ContractStatus.ACTIVE);
            assertThat(contract.getSignedBy()).isEqualTo(USER_ID);
            assertThat(contract.getSignedAt()).isNotNull();
        }

        @Test
        void registersContractSignedEvent() {
            Contract contract = createDraftContract();
            contract.clearDomainEvents();

            contract.sign(USER_ID);

            assertThat(contract.getDomainEvents()).hasSize(1);
            ContractSignedEvent event = (ContractSignedEvent) contract.getDomainEvents().get(0);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(event.getContractNumber()).isEqualTo(CONTRACT_NUMBER);
        }

        @Test
        void rejectsFromActive() {
            Contract contract = createSignedContract();
            assertThatThrownBy(() -> contract.sign(USER_ID))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── suspend / reactivate ─────────────────────────────────────────

    @Nested
    class SuspendAndReactivate {

        @Test
        void suspend_transitionsToSuspended() {
            Contract contract = createSignedContract();

            contract.suspend();

            assertThat(contract.getStatus()).isEqualTo(ContractStatus.SUSPENDED);
            assertThat(contract.getDomainEvents()).hasSize(1);
            assertThat(contract.getDomainEvents().get(0)).isInstanceOf(ContractSuspendedEvent.class);
        }

        @Test
        void reactivate_transitionsToActive() {
            Contract contract = createSignedContract();
            contract.suspend();
            contract.clearDomainEvents();

            contract.reactivate();

            assertThat(contract.getStatus()).isEqualTo(ContractStatus.ACTIVE);
            assertThat(contract.getDomainEvents()).hasSize(1);
            assertThat(contract.getDomainEvents().get(0)).isInstanceOf(ContractReactivatedEvent.class);
        }

        @Test
        void suspendRequiresActive() {
            Contract contract = createDraftContract();
            assertThatThrownBy(contract::suspend)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void reactivateRequiresSuspended() {
            Contract contract = createSignedContract();
            assertThatThrownBy(contract::reactivate)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── terminate ────────────────────────────────────────────────────

    @Nested
    class Terminate {

        @Test
        void transitionsToTerminated() {
            Contract contract = createSignedContract();

            contract.terminate();

            assertThat(contract.getStatus()).isEqualTo(ContractStatus.TERMINATED);
            assertThat(contract.getDomainEvents()).hasSize(1);
            assertThat(contract.getDomainEvents().get(0)).isInstanceOf(ContractTerminatedEvent.class);
        }

        @Test
        void rejectsFromDraft() {
            Contract contract = createDraftContract();
            assertThatThrownBy(contract::terminate)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── markExpired ──────────────────────────────────────────────────

    @Nested
    class MarkExpired {

        @Test
        void transitionsToExpired() {
            Contract contract = createSignedContract();

            contract.markExpired();

            assertThat(contract.getStatus()).isEqualTo(ContractStatus.EXPIRED);
            assertThat(contract.getDomainEvents()).hasSize(1);
            assertThat(contract.getDomainEvents().get(0)).isInstanceOf(ContractExpiredEvent.class);
        }

        @Test
        void rejectsFromDraft() {
            Contract contract = createDraftContract();
            assertThatThrownBy(contract::markExpired)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── calculateRevenueShare ─────────────────────────────────────────

    @Nested
    class CalculateRevenueShare {

        @Test
        void calculatesSharesFromRatio() {
            Contract contract = Contract.create(TENANT_ID, CONTRACT_NUMBER,
                "revenue_share", "STANDARD", new BigDecimal("0.3000"),
                Instant.now().plusSeconds(86400));

            Contract.RevenueShareResult result = contract.calculateRevenueShare(10000);

            assertThat(result.platformShare()).isEqualTo(7000);
            assertThat(result.partnerShare()).isEqualTo(3000);
        }

        @Test
        void differentRatio() {
            Contract contract = Contract.create(TENANT_ID, CONTRACT_NUMBER,
                "revenue_share", "STANDARD", new BigDecimal("0.1500"),
                Instant.now().plusSeconds(86400));

            Contract.RevenueShareResult result = contract.calculateRevenueShare(20000);

            assertThat(result.platformShare()).isEqualTo(17000);
            assertThat(result.partnerShare()).isEqualTo(3000);
        }
    }
}
