package com.smartlivestock.commerce.application.query;

import com.smartlivestock.commerce.application.assembler.ContractAssembler;
import com.smartlivestock.commerce.application.assembler.RevenuePeriodAssembler;
import com.smartlivestock.commerce.application.dto.ContractResponse;
import com.smartlivestock.commerce.application.dto.RevenuePeriodResponse;
import com.smartlivestock.commerce.domain.model.ContractStatus;
import com.smartlivestock.commerce.domain.repository.ContractRepository;
import com.smartlivestock.commerce.domain.repository.RevenuePeriodRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/**
 * Read-only query service for revenue and contract read models.
 * <p>
 * Handles GET endpoints. No event publishing.
 */
@Service
public class RevenueQueryService {

    private final RevenuePeriodRepository revenuePeriodRepository;
    private final ContractRepository contractRepository;

    public RevenueQueryService(RevenuePeriodRepository revenuePeriodRepository,
                               ContractRepository contractRepository) {
        this.revenuePeriodRepository = revenuePeriodRepository;
        this.contractRepository = contractRepository;
    }

    /**
     * List revenue periods for a contract.
     */
    public List<RevenuePeriodResponse> listByContractId(Long contractId) {
        return RevenuePeriodAssembler.toResponseList(
            revenuePeriodRepository.findByContractId(contractId));
    }

    /**
     * List revenue periods for a tenant.
     */
    public List<RevenuePeriodResponse> listByTenantId(Long tenantId) {
        return RevenuePeriodAssembler.toResponseList(
            revenuePeriodRepository.findByTenantId(tenantId));
    }

    /**
     * Get a single revenue period by ID.
     */
    public Optional<RevenuePeriodResponse> findById(Long id) {
        return revenuePeriodRepository.findById(id)
            .map(RevenuePeriodAssembler::toResponse);
    }

    /**
     * List all contracts (admin view, all statuses).
     */
    public List<ContractResponse> listAllContracts() {
        return ContractAssembler.toResponseList(
            contractRepository.findByStatus(ContractStatus.ACTIVE));
    }

    /**
     * Get contract by ID (admin detail view).
     */
    public Optional<ContractResponse> findContractById(Long id) {
        return contractRepository.findById(id)
            .map(ContractAssembler::toResponse);
    }
}
