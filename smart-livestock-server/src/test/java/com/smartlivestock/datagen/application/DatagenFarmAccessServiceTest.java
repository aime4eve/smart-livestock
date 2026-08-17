package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.DatagenOperatorContext.DatagenOperatorRole;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DatagenFarmAccessServiceTest {
    @Mock private FarmRepository farmRepository;
    @InjectMocks private DatagenFarmAccessService service;

    @Test
    void requireAccessibleFarm_platformAdmin_canAccessAnyFarm() {
        Farm farm = farm(3L);
        when(farmRepository.findById(3L)).thenReturn(Optional.of(farm));

        assertSame(farm, service.requireAccessibleFarm(
                3L, new DatagenOperatorContext(1L, null, DatagenOperatorRole.PLATFORM_ADMIN)));
    }

    @Test
    void requireAccessibleFarm_b2bAdmin_canAccessOwnTenantFarm() {
        Farm farm = farm(3L);
        when(farmRepository.findById(3L)).thenReturn(Optional.of(farm));

        assertSame(farm, service.requireAccessibleFarm(
                3L, new DatagenOperatorContext(2L, 1L, DatagenOperatorRole.B2B_ADMIN)));
    }

    @Test
    void requireAccessibleFarm_b2bAdmin_cannotAccessOtherTenantFarm() {
        when(farmRepository.findById(3L)).thenReturn(Optional.of(farm(3L)));

        ApiException ex = assertThrows(ApiException.class, () -> service.requireAccessibleFarm(
                3L, new DatagenOperatorContext(2L, 9L, DatagenOperatorRole.B2B_ADMIN)));
        assertEquals(ErrorCode.AUTH_FORBIDDEN, ex.getCode());
    }

    @Test
    void requireAccessibleFarm_missingFarm_returnsNotFound() {
        when(farmRepository.findById(404L)).thenReturn(Optional.empty());

        ApiException ex = assertThrows(ApiException.class, () -> service.requireAccessibleFarm(
                404L, new DatagenOperatorContext(1L, null, DatagenOperatorRole.PLATFORM_ADMIN)));
        assertEquals(ErrorCode.RESOURCE_NOT_FOUND, ex.getCode());
    }

    private Farm farm(Long id) {
        Farm farm = new Farm();
        farm.setId(id);
        farm.setTenantId(1L);
        return farm;
    }
}
