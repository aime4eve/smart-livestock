package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.FenceZoneRepository;
import com.smartlivestock.ranch.domain.service.BufferPolygonCalculator;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FenceApplicationServiceTest {

    private static final long FENCE_ID = 1L;

    @Mock private FenceRepository fenceRepository;
    @Mock private AlertRepository alertRepository;
    @Mock private FenceZoneRepository fenceZoneRepository;
    @Mock private BufferPolygonCalculator bufferPolygonCalculator;

    private FenceApplicationService service;

    @BeforeEach
    void setUp() {
        service = new FenceApplicationService(
                fenceRepository, alertRepository, fenceZoneRepository, bufferPolygonCalculator);
    }

    @Test
    void deleteFence_withAlerts_deletesReadStatusAlertsZonesAndFence() {
        when(fenceRepository.findById(FENCE_ID)).thenReturn(Optional.of(new Fence()));
        when(alertRepository.deleteByFenceId(FENCE_ID)).thenReturn(664);

        int deleted = service.deleteFence(FENCE_ID, true);

        assertEquals(664, deleted);
        var inOrder = inOrder(alertRepository, fenceZoneRepository, fenceRepository);
        // read_status must go first: it holds a non-cascading FK on alerts.id
        inOrder.verify(alertRepository).deleteReadStatusByFenceId(FENCE_ID);
        inOrder.verify(alertRepository).deleteByFenceId(FENCE_ID);
        inOrder.verify(fenceZoneRepository).deleteByFenceId(FENCE_ID);
        inOrder.verify(fenceRepository).deleteById(FENCE_ID);
        verify(alertRepository, never()).clearFenceReference(anyLong());
    }

    @Test
    void deleteFence_keepAlerts_detachesReferencesInsteadOfDeleting() {
        when(fenceRepository.findById(FENCE_ID)).thenReturn(Optional.of(new Fence()));
        when(alertRepository.clearFenceReference(FENCE_ID)).thenReturn(12);

        int deleted = service.deleteFence(FENCE_ID, false);

        assertEquals(0, deleted);
        verify(alertRepository).clearFenceReference(FENCE_ID);
        verify(alertRepository, never()).deleteByFenceId(anyLong());
        verify(alertRepository, never()).deleteReadStatusByFenceId(anyLong());
        verify(fenceZoneRepository).deleteByFenceId(FENCE_ID);
        verify(fenceRepository).deleteById(FENCE_ID);
    }

    @Test
    void deleteFence_missingFence_throwsNotFoundWithoutSideEffects() {
        when(fenceRepository.findById(FENCE_ID)).thenReturn(Optional.empty());

        ApiException ex = assertThrows(ApiException.class,
                () -> service.deleteFence(FENCE_ID, true));

        assertEquals(ErrorCode.RESOURCE_NOT_FOUND, ex.getCode());
        verifyNoInteractions(alertRepository, fenceZoneRepository);
        verify(fenceRepository, never()).deleteById(anyLong());
    }
}
