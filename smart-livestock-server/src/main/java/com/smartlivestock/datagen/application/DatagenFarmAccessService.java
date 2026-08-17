package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.DatagenOperatorContext.DatagenOperatorRole;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DatagenFarmAccessService {
    private final FarmRepository farmRepository;

    public Farm requireAccessibleFarm(Long farmId, DatagenOperatorContext operator) {
        Farm farm = farmRepository.findById(farmId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND, "error.datagen.farmNotFound",
                        new Object[]{farmId}));
        if (operator.role() != DatagenOperatorRole.PLATFORM_ADMIN
                && !farm.getTenantId().equals(operator.tenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.datagen.farmForbidden");
        }
        return farm;
    }
}
