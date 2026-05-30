package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Contract;
import com.smartlivestock.commerce.domain.model.ContractStatus;
import com.smartlivestock.commerce.domain.model.RevenuePeriod;
import com.smartlivestock.commerce.domain.repository.ContractRepository;
import com.smartlivestock.commerce.domain.repository.RevenuePeriodRepository;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Application service handling revenue period write operations.
 * <p>
 * Pattern: load aggregate → call domain method → save → publish events → clear.
 */
@Service
public class RevenueApplicationService {

    private final ContractRepository contractRepository;
    private final RevenuePeriodRepository revenuePeriodRepository;
    private final DomainEventPublisher domainEventPublisher;

    public RevenueApplicationService(ContractRepository contractRepository,
                                     RevenuePeriodRepository revenuePeriodRepository,
                                     DomainEventPublisher domainEventPublisher) {
        this.contractRepository = contractRepository;
        this.revenuePeriodRepository = revenuePeriodRepository;
        this.domainEventPublisher = domainEventPublisher;
    }

    /**
     * Calculate a revenue period for a contract.
     * <p>
     * Validates the contract is ACTIVE before calculating.
     *
     * @param contractId the contract identifier
     * @param periodStart period start date
     * @param periodEnd period end date
     * @param grossAmountCents gross revenue in cents
     * @return created RevenuePeriod in PENDING status
     */
    public RevenuePeriod calculatePeriod(Long contractId, LocalDate periodStart,
                                         LocalDate periodEnd, int grossAmountCents) {
        Contract contract = loadAndValidateActiveContract(contractId);
        Contract.RevenueShareResult shares = contract.calculateRevenueShare(grossAmountCents);

        RevenuePeriod period = RevenuePeriod.create(
            contractId, contract.getTenantId(),
            periodStart, periodEnd,
            grossAmountCents, shares.platformShare(), shares.partnerShare(),
            contract.getRevenueShareRatio() != null ? contract.getRevenueShareRatio() : BigDecimal.ZERO);

        RevenuePeriod saved = revenuePeriodRepository.save(period);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Confirm a revenue period by platform (PENDING → PLATFORM_CONFIRMED).
     */
    public RevenuePeriod confirmByPlatform(Long periodId) {
        RevenuePeriod period = loadPeriod(periodId);
        period.confirmByPlatform();
        RevenuePeriod saved = revenuePeriodRepository.save(period);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Confirm a revenue period by partner (PLATFORM_CONFIRMED → PARTNER_CONFIRMED).
     */
    public RevenuePeriod confirmByPartner(Long periodId) {
        RevenuePeriod period = loadPeriod(periodId);
        period.confirmByPartner();
        RevenuePeriod saved = revenuePeriodRepository.save(period);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Settle a revenue period (PARTNER_CONFIRMED → SETTLED).
     */
    public RevenuePeriod settle(Long periodId) {
        RevenuePeriod period = loadPeriod(periodId);
        period.settle(Instant.now());
        RevenuePeriod saved = revenuePeriodRepository.save(period);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Recalculate a revenue period with new amounts, resetting to PENDING.
     * <p>
     * Validates the contract is ACTIVE before recalculating.
     *
     * @param periodId the period to recalculate
     * @param grossAmountCents the new gross revenue in cents
     * @return updated RevenuePeriod in PENDING status
     */
    public RevenuePeriod recalculate(Long periodId, int grossAmountCents) {
        RevenuePeriod period = loadPeriod(periodId);
        Contract contract = loadAndValidateActiveContract(period.getContractId());
        Contract.RevenueShareResult shares = contract.calculateRevenueShare(grossAmountCents);

        period.recalculate(grossAmountCents, shares.platformShare(), shares.partnerShare(),
            contract.getRevenueShareRatio());

        RevenuePeriod saved = revenuePeriodRepository.save(period);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    // ── Helpers ────────────────────────────────────────────────────

    private Contract loadAndValidateActiveContract(Long contractId) {
        Contract contract = contractRepository.findById(contractId)
            .orElseThrow(() -> new DomainException(ErrorCode.CONTRACT_NOT_ACTIVE,
                "Contract not found: " + contractId));
        if (contract.getStatus() != ContractStatus.ACTIVE) {
            throw new DomainException(ErrorCode.CONTRACT_NOT_ACTIVE,
                "Contract is not active: " + contractId);
        }
        return contract;
    }

    private RevenuePeriod loadPeriod(Long periodId) {
        return revenuePeriodRepository.findById(periodId)
            .orElseThrow(() -> new DomainException(ErrorCode.RESOURCE_NOT_FOUND,
                "Revenue period not found: " + periodId));
    }
}
