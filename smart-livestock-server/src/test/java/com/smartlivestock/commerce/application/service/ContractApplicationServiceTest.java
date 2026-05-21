package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Contract;
import com.smartlivestock.commerce.domain.model.ContractStatus;
import com.smartlivestock.commerce.domain.repository.ContractRepository;
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
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ContractApplicationServiceTest {

    @Mock
    private ContractRepository contractRepository;

    @Mock
    private DomainEventPublisher domainEventPublisher;

    private ContractApplicationService createService() {
        return new ContractApplicationService(contractRepository, domainEventPublisher);
    }

    // ── Test factories ─────────────────────────────────────────────

    private Contract createDraftContract() {
        return Contract.create(1L, "CTR-001", "revenue_share", "PREMIUM",
            new BigDecimal("0.30"), Instant.now());
    }

    private Contract createSignedContract() {
        Contract contract = createDraftContract();
        contract.sign(100L, Instant.now());
        return contract;
    }

    private Contract createSuspendedContract() {
        Contract contract = createSignedContract();
        contract.suspend();
        return contract;
    }

    // ── create ─────────────────────────────────────────────────────

    @Nested
    class Create {

        @Test
        void createsDraftContract() {
            when(contractRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            ContractApplicationService service = createService();
            Contract result = service.create(1L, "CTR-001", "revenue_share", "PREMIUM",
                new BigDecimal("0.30"));

            assertThat(result.getStatus()).isEqualTo(ContractStatus.DRAFT);
            assertThat(result.getContractNumber()).isEqualTo("CTR-001");
            verify(contractRepository).save(any());
            verify(domainEventPublisher).publishDomainEvents(any());
        }

        @Test
        void invalidRevenueShareRatio_throws() {
            ContractApplicationService service = createService();
            assertThatThrownBy(() -> service.create(1L, "CTR-002", "revenue_share", "PREMIUM",
                new BigDecimal("1.50")))
                .isInstanceOf(DomainException.class);
        }
    }

    // ── sign ───────────────────────────────────────────────────────

    @Nested
    class Sign {

        @Test
        void draftContract_signsSuccessfully() {
            Contract draft = createDraftContract();
            when(contractRepository.findById(1L)).thenReturn(Optional.of(draft));
            when(contractRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            ContractApplicationService service = createService();
            Contract result = service.sign(1L, 100L);

            assertThat(result.getStatus()).isEqualTo(ContractStatus.ACTIVE);
            assertThat(result.getSignedBy()).isEqualTo(100L);
            verify(domainEventPublisher).publishDomainEvents(any());
        }

        @Test
        void contractNotFound_throws() {
            when(contractRepository.findById(999L)).thenReturn(Optional.empty());

            ContractApplicationService service = createService();
            assertThatThrownBy(() -> service.sign(999L, 100L))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND));
        }
    }

    // ── suspend ────────────────────────────────────────────────────

    @Nested
    class Suspend {

        @Test
        void activeContract_suspends() {
            Contract active = createSignedContract();
            when(contractRepository.findById(1L)).thenReturn(Optional.of(active));
            when(contractRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            ContractApplicationService service = createService();
            Contract result = service.suspend(1L);

            assertThat(result.getStatus()).isEqualTo(ContractStatus.SUSPENDED);
            verify(domainEventPublisher).publishDomainEvents(any());
        }
    }

    // ── reactivate ─────────────────────────────────────────────────

    @Nested
    class Reactivate {

        @Test
        void suspendedContract_reactivates() {
            Contract suspended = createSuspendedContract();
            when(contractRepository.findById(1L)).thenReturn(Optional.of(suspended));
            when(contractRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            ContractApplicationService service = createService();
            Contract result = service.reactivate(1L);

            assertThat(result.getStatus()).isEqualTo(ContractStatus.ACTIVE);
            verify(domainEventPublisher).publishDomainEvents(any());
        }
    }

    // ── terminate ──────────────────────────────────────────────────

    @Nested
    class Terminate {

        @Test
        void activeContract_terminates() {
            Contract active = createSignedContract();
            when(contractRepository.findById(1L)).thenReturn(Optional.of(active));
            when(contractRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            ContractApplicationService service = createService();
            Contract result = service.terminate(1L);

            assertThat(result.getStatus()).isEqualTo(ContractStatus.TERMINATED);
            verify(domainEventPublisher).publishDomainEvents(any());
        }

        @Test
        void contractNotFound_doesNotPublish() {
            when(contractRepository.findById(999L)).thenReturn(Optional.empty());

            ContractApplicationService service = createService();
            assertThatThrownBy(() -> service.terminate(999L))
                .isInstanceOf(DomainException.class);

            verify(domainEventPublisher, never()).publishDomainEvents(any());
        }
    }
}
