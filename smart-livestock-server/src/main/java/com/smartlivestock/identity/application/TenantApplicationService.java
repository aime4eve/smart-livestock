package com.smartlivestock.identity.application;

import com.smartlivestock.identity.application.command.CreateTenantCommand;
import com.smartlivestock.identity.application.dto.TenantDto;
import com.smartlivestock.identity.domain.model.Tenant;
import com.smartlivestock.identity.domain.model.TenantPhase;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.ZoneId;

@Service
@RequiredArgsConstructor
public class TenantApplicationService {

    private final TenantRepository tenantRepository;
    private final TenantZoneResolver tenantZoneResolver;

    /** Validates an IANA timezone name; blank → null (inherit next level in the chain). */
    public static String normalizeTimezone(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return ZoneId.of(raw.trim()).getId();
        } catch (Exception e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "tenant.invalidTimezone", new Object[]{raw});
        }
    }

    @Transactional
    public TenantDto createTenant(CreateTenantCommand command) {
        Tenant tenant = new Tenant(command.name(), command.contactName(), command.contactPhone());
        tenant.setTimezone(normalizeTimezone(command.timezone()));
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
    public TenantDto updateTenant(Long id, String name, String contactName, String contactPhone) {
        return updateTenant(id, name, contactName, contactPhone, null);
    }

    @Transactional
    public TenantDto updateTenant(Long id, String name, String contactName, String contactPhone, String timezone) {
        Tenant tenant = tenantRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + id));
        if (name != null) tenant.setName(name);
        if (contactName != null) tenant.setContactName(contactName);
        if (contactPhone != null) tenant.setContactPhone(contactPhone);
        if (timezone != null) tenant.setTimezone(normalizeTimezone(timezone));
        Tenant saved = tenantRepository.save(tenant);
        tenantZoneResolver.evictTenant(id);
        return TenantDto.from(saved);
    }

    @Transactional
    public void transitionToBatch(Long id) {
        Tenant tenant = tenantRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + id));
        tenant.transitionToBatch();
        tenantRepository.save(tenant);
    }

    /** BATCH → SAMPLE; idempotent when already SAMPLE (ruling follow-up 2026-10-14). */
    @Transactional
    public void revertToSample(Long id) {
        Tenant tenant = tenantRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + id));
        if (tenant.getPhase() == TenantPhase.SAMPLE) return;
        tenant.revertToSample();
        tenantRepository.save(tenant);
    }
}
