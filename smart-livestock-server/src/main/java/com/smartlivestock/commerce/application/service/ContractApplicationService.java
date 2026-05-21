package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Contract;
import com.smartlivestock.commerce.domain.repository.ContractRepository;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Application service handling contract write operations.
 * <p>
 * Pattern: load aggregate → call domain method → save → publish events → clear.
 */
@Service
public class ContractApplicationService {

    private final ContractRepository contractRepository;
    private final DomainEventPublisher domainEventPublisher;

    public ContractApplicationService(ContractRepository contractRepository,
                                      DomainEventPublisher domainEventPublisher) {
        this.contractRepository = contractRepository;
        this.domainEventPublisher = domainEventPublisher;
    }

    /**
     * Create a new contract in DRAFT status.
     */
    public Contract create(Long tenantId, String contractNumber, String billingModel,
                           String effectiveTier, BigDecimal revenueShareRatio) {
        Contract contract = Contract.create(tenantId, contractNumber, billingModel,
            effectiveTier, revenueShareRatio, Instant.now());
        Contract saved = contractRepository.save(contract);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Sign a draft contract (DRAFT → ACTIVE).
     */
    public Contract sign(Long contractId, Long userId) {
        Contract contract = loadContract(contractId);
        contract.sign(userId, Instant.now());
        Contract saved = contractRepository.save(contract);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Suspend an active contract (ACTIVE → SUSPENDED).
     */
    public Contract suspend(Long contractId) {
        Contract contract = loadContract(contractId);
        contract.suspend();
        Contract saved = contractRepository.save(contract);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Reactivate a suspended contract (SUSPENDED → ACTIVE).
     */
    public Contract reactivate(Long contractId) {
        Contract contract = loadContract(contractId);
        contract.reactivate();
        Contract saved = contractRepository.save(contract);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Terminate an active contract (ACTIVE → TERMINATED).
     */
    public Contract terminate(Long contractId) {
        Contract contract = loadContract(contractId);
        contract.terminate();
        Contract saved = contractRepository.save(contract);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    // ── Helpers ────────────────────────────────────────────────────

    private Contract loadContract(Long contractId) {
        return contractRepository.findById(contractId)
            .orElseThrow(() -> new DomainException(ErrorCode.CONTRACT_NOT_ACTIVE,
                "Contract not found: " + contractId));
    }
}
