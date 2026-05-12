package com.smartlivestock.identity.application;

import com.smartlivestock.identity.application.command.CreateTenantCommand;
import com.smartlivestock.identity.application.dto.TenantDto;
import com.smartlivestock.identity.domain.model.Tenant;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TenantApplicationService {

    private final TenantRepository tenantRepository;

    @Transactional
    public TenantDto createTenant(CreateTenantCommand command) {
        Tenant tenant = new Tenant(command.name(), command.contactName(), command.contactPhone());
        Tenant saved = tenantRepository.save(tenant);
        return TenantDto.from(saved);
    }

    @Transactional(readOnly = true)
    public TenantDto getTenant(Long id) {
        Tenant tenant = tenantRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + id));
        return TenantDto.from(tenant);
    }

    @Transactional
    public void transitionToBatch(Long id) {
        Tenant tenant = tenantRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + id));
        tenant.transitionToBatch();
        tenantRepository.save(tenant);
    }
}
