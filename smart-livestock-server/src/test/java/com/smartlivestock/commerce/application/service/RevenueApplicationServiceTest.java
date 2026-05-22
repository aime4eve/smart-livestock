package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Contract;
import com.smartlivestock.commerce.domain.model.RevenuePeriod;
import com.smartlivestock.commerce.domain.model.RevenueSettlementStatus;
import com.smartlivestock.commerce.domain.repository.ContractRepository;
import com.smartlivestock.commerce.domain.repository.RevenuePeriodRepository;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RevenueApplicationServiceTest {

    @Mock
    private ContractRepository contractRepository;

    @Mock
    private RevenuePeriodRepository revenuePeriodRepository;

    @Mock
    private DomainEventPublisher domainEventPublisher;

    private RevenueApplicationService createService() {
        return new RevenueApplicationService(contractRepository, revenuePeriodRepository, domainEventPublisher);
    }

    private Contract createActiveContract() {
        Contract contract = Contract.create(1L, "CTR-001", "revenue_share", "PREMIUM",
            new BigDecimal("0.30"), Instant.now());
        contract.sign(100L, Instant.now());
        return contract;
    }

    private RevenuePeriod createPendingPeriod() {
        return RevenuePeriod.create(1L, 1L,
            LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
            10000, 7000, 3000, new BigDecimal("0.30"));
    }

    private RevenuePeriod createPlatformConfirmedPeriod() {
        RevenuePeriod period = createPendingPeriod();
        period.confirmByPlatform();
        return period;
    }

    private RevenuePeriod createPartnerConfirmedPeriod() {
        RevenuePeriod period = createPlatformConfirmedPeriod();
        period.confirmByPartner();
        return period;
    }

    // ── calculatePeriod ──────────────────────────────────────────────

    @Nested
    class CalculatePeriod {

        @Test
        void calculatesPeriodForActiveContract() {
            when(contractRepository.findById(1L)).thenReturn(Optional.of(createActiveContract()));
            when(revenuePeriodRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            RevenueApplicationService service = createService();
            RevenuePeriod result = service.calculatePeriod(1L,
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), 10000);

            assertThat(result.getStatus()).isEqualTo(RevenueSettlementStatus.PENDING);
            assertThat(result.getGrossAmount()).isEqualTo(10000);
            assertThat(result.getContractId()).isEqualTo(1L);
            verify(domainEventPublisher).publishDomainEvents(any());
        }

        @Test
        void inactiveContract_throws() {
            Contract draft = Contract.create(1L, "CTR-001", "revenue_share", "PREMIUM",
                new BigDecimal("0.30"), Instant.now());
            when(contractRepository.findById(1L)).thenReturn(Optional.of(draft));

            RevenueApplicationService service = createService();
            assertThatThrownBy(() -> service.calculatePeriod(1L,
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), 10000))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.CONTRACT_NOT_ACTIVE));

            verify(domainEventPublisher, never()).publishDomainEvents(any());
        }
    }

    // ── confirmByPlatform ────────────────────────────────────────────

    @Nested
    class ConfirmByPlatform {

        @Test
        void pendingPeriod_confirmedByPlatform() {
            when(revenuePeriodRepository.findById(1L)).thenReturn(Optional.of(createPendingPeriod()));
            when(revenuePeriodRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            RevenueApplicationService service = createService();
            RevenuePeriod result = service.confirmByPlatform(1L);

            assertThat(result.getStatus()).isEqualTo(RevenueSettlementStatus.PLATFORM_CONFIRMED);
            verify(domainEventPublisher).publishDomainEvents(any());
        }
    }

    // ── confirmByPartner ─────────────────────────────────────────────

    @Nested
    class ConfirmByPartner {

        @Test
        void platformConfirmedPeriod_confirmedByPartner() {
            when(revenuePeriodRepository.findById(1L)).thenReturn(Optional.of(createPlatformConfirmedPeriod()));
            when(revenuePeriodRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            RevenueApplicationService service = createService();
            RevenuePeriod result = service.confirmByPartner(1L);

            assertThat(result.getStatus()).isEqualTo(RevenueSettlementStatus.PARTNER_CONFIRMED);
            verify(domainEventPublisher).publishDomainEvents(any());
        }
    }

    // ── settle ───────────────────────────────────────────────────────

    @Nested
    class Settle {

        @Test
        void partnerConfirmedPeriod_settles() {
            when(revenuePeriodRepository.findById(1L)).thenReturn(Optional.of(createPartnerConfirmedPeriod()));
            when(revenuePeriodRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            RevenueApplicationService service = createService();
            RevenuePeriod result = service.settle(1L);

            assertThat(result.getStatus()).isEqualTo(RevenueSettlementStatus.SETTLED);
            assertThat(result.getSettledAt()).isNotNull();
            verify(domainEventPublisher).publishDomainEvents(any());
        }
    }

    // ── recalculate ──────────────────────────────────────────────────

    @Nested
    class Recalculate {

        @Test
        void updatesExistingPeriod_inPlace() {
            RevenuePeriod period = createPendingPeriod();
            assertThat(period.getGrossAmount()).isEqualTo(10000);

            when(revenuePeriodRepository.findById(1L)).thenReturn(Optional.of(period));
            when(contractRepository.findById(1L)).thenReturn(Optional.of(createActiveContract()));
            when(revenuePeriodRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            RevenueApplicationService service = createService();
            RevenuePeriod result = service.recalculate(1L, 20000);

            assertThat(result.getGrossAmount()).isEqualTo(20000);
            assertThat(result.getStatus()).isEqualTo(RevenueSettlementStatus.PENDING);
            verify(domainEventPublisher).publishDomainEvents(any());
        }

        @Test
        void settledPeriod_throwsStateConflict() {
            RevenuePeriod period = createPartnerConfirmedPeriod();
            period.settle(Instant.now());

            when(revenuePeriodRepository.findById(1L)).thenReturn(Optional.of(period));
            when(contractRepository.findById(1L)).thenReturn(Optional.of(createActiveContract()));

            RevenueApplicationService service = createService();
            assertThatThrownBy(() -> service.recalculate(1L, 20000))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }
}
