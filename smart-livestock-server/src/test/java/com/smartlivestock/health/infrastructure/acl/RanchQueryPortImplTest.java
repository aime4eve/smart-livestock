package com.smartlivestock.health.infrastructure.acl;

import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * NIX-381 Task 0 fix: scheduler threads resolve the tenant explicitly from
 * the farm ({@code farms.tenant_id}) — no farm, no tenant, or a missing farm
 * yields empty so the caller can skip with a warning instead of silently
 * falling back to a default tier.
 */
@ExtendWith(MockitoExtension.class)
class RanchQueryPortImplTest {

    private static final Long FARM_ID = 5L;
    private static final Long TENANT_ID = 7L;

    @Mock private LivestockRepository livestockRepository;
    @Mock private AlertRepository alertRepository;
    @Mock private SpringDataAlertRepository springDataAlertRepository;
    @Mock private SpringDataAlertReadStatusRepository readStatusRepository;
    @Mock private FarmRepository farmRepository;

    private RanchQueryPortImpl port() {
        return new RanchQueryPortImpl(livestockRepository, alertRepository,
                springDataAlertRepository, readStatusRepository, farmRepository);
    }

    @Test
    void farmFound_returnsTenantId() {
        Farm farm = new Farm();
        farm.setId(FARM_ID);
        farm.setTenantId(TENANT_ID);
        when(farmRepository.findById(FARM_ID)).thenReturn(Optional.of(farm));

        assertThat(port().findTenantIdByFarm(FARM_ID)).contains(TENANT_ID);
    }

    @Test
    void farmMissing_empty() {
        when(farmRepository.findById(FARM_ID)).thenReturn(Optional.empty());

        assertThat(port().findTenantIdByFarm(FARM_ID)).isEmpty();
    }

    @Test
    void farmWithoutTenant_empty() {
        Farm farm = new Farm();
        farm.setId(FARM_ID);
        farm.setTenantId(null);
        when(farmRepository.findById(FARM_ID)).thenReturn(Optional.of(farm));

        assertThat(port().findTenantIdByFarm(FARM_ID)).isEmpty();
    }

    @Test
    void nullFarmId_empty() {
        assertThat(port().findTenantIdByFarm(null)).isEmpty();
    }
}
