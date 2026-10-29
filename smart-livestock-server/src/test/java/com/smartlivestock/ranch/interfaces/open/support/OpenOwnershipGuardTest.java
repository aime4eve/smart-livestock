package com.smartlivestock.ranch.interfaces.open.support;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

/**
 * NIX-333: every Open API detail endpoint must prove the addressed resource
 * belongs to the path farm; cross-farm and unknown ids both answer 404 so the
 * response never reveals that the id exists in another farm.
 */
@ExtendWith(MockitoExtension.class)
class OpenOwnershipGuardTest {

    private static final long FARM_A = 10L;
    private static final long FARM_B = 20L;

    @Mock private LivestockRepository livestockRepository;
    @Mock private FenceRepository fenceRepository;
    @Mock private AlertRepository alertRepository;

    private OpenOwnershipGuard guard;

    @BeforeEach
    void setUp() {
        guard = new OpenOwnershipGuard(livestockRepository, fenceRepository, alertRepository);
    }

    private static void assertNotFound(Runnable call) {
        assertThatThrownBy(call::run)
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND));
    }

    @Nested
    class LivestockInFarm {
        private Livestock inFarmA() {
            Livestock l = new Livestock();
            l.setId(1L);
            l.setFarmId(FARM_A);
            return l;
        }

        @Test
        void sameFarm_returnsEntity() {
            when(livestockRepository.findById(1L)).thenReturn(Optional.of(inFarmA()));
            assertThat(guard.requireLivestockInFarm(1L, FARM_A).getId()).isEqualTo(1L);
        }

        @Test
        void crossFarm_is404() {
            when(livestockRepository.findById(1L)).thenReturn(Optional.of(inFarmA()));
            assertNotFound(() -> guard.requireLivestockInFarm(1L, FARM_B));
        }

        @Test
        void unknownId_is404() {
            when(livestockRepository.findById(99L)).thenReturn(Optional.empty());
            assertNotFound(() -> guard.requireLivestockInFarm(99L, FARM_A));
        }
    }

    @Nested
    class FenceInFarm {
        private Fence inFarmA() {
            Fence f = new Fence();
            f.setId(2L);
            f.setFarmId(FARM_A);
            return f;
        }

        @Test
        void sameFarm_returnsEntity() {
            when(fenceRepository.findById(2L)).thenReturn(Optional.of(inFarmA()));
            assertThat(guard.requireFenceInFarm(2L, FARM_A).getId()).isEqualTo(2L);
        }

        @Test
        void crossFarm_is404() {
            when(fenceRepository.findById(2L)).thenReturn(Optional.of(inFarmA()));
            assertNotFound(() -> guard.requireFenceInFarm(2L, FARM_B));
        }

        @Test
        void unknownId_is404() {
            when(fenceRepository.findById(99L)).thenReturn(Optional.empty());
            assertNotFound(() -> guard.requireFenceInFarm(99L, FARM_A));
        }
    }

    @Nested
    class AlertInFarm {
        private Alert inFarmA() {
            Alert a = new Alert();
            a.setId(3L);
            a.setFarmId(FARM_A);
            return a;
        }

        @Test
        void sameFarm_returnsEntity() {
            when(alertRepository.findById(3L)).thenReturn(Optional.of(inFarmA()));
            assertThat(guard.requireAlertInFarm(3L, FARM_A).getId()).isEqualTo(3L);
        }

        @Test
        void crossFarm_is404() {
            when(alertRepository.findById(3L)).thenReturn(Optional.of(inFarmA()));
            assertNotFound(() -> guard.requireAlertInFarm(3L, FARM_B));
        }

        @Test
        void unknownId_is404() {
            when(alertRepository.findById(99L)).thenReturn(Optional.empty());
            assertNotFound(() -> guard.requireAlertInFarm(99L, FARM_A));
        }
    }

    @Test
    void livestockIdsOf_collectsFarmIds() {
        Livestock a = new Livestock();
        a.setId(1L);
        Livestock b = new Livestock();
        b.setId(2L);
        when(livestockRepository.findByFarmId(FARM_A)).thenReturn(List.of(a, b));

        assertThat(guard.livestockIdsOf(FARM_A)).containsExactlyInAnyOrder(1L, 2L);
    }

    @Test
    void livestockIdsOf_emptyFarm() {
        when(livestockRepository.findByFarmId(FARM_B)).thenReturn(List.of());
        assertThat(guard.livestockIdsOf(FARM_B)).isEmpty();
    }
}
