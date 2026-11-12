package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.application.command.CreateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.application.signal.SignalEventType;
import com.smartlivestock.ranch.application.signal.SignalRevisionService;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.FenceZoneRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.domain.service.BufferPolygonCalculator;
import com.smartlivestock.ranch.domain.service.FenceLivestockCounter;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
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
    @Mock private LivestockRepository livestockRepository;
    @Mock private BufferPolygonCalculator bufferPolygonCalculator;
    @Mock private SignalRevisionService signalRevisionService;

    private FenceApplicationService service;

    @BeforeEach
    void setUp() {
        service = new FenceApplicationService(
                fenceRepository, alertRepository, fenceZoneRepository, livestockRepository,
                bufferPolygonCalculator, new FenceLivestockCounter(),
                signalRevisionService);
    }

    @Test
    void deleteFence_withAlerts_deletesReadStatusAlertsZonesAndFence() {
        when(fenceRepository.findById(FENCE_ID)).thenReturn(Optional.of(new Fence(
                1L, "test", java.util.List.of(), "#FF0000")));
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
        verify(signalRevisionService).bumpStatus(
                1L, SignalEventType.FENCE_SIGNAL_CHANGED, "FENCE", FENCE_ID);
        verify(signalRevisionService).bumpFenceGeometry(
                1L, SignalEventType.FENCE_GEOMETRY_CHANGED, "FENCE", FENCE_ID);
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

    private static final List<GpsCoordinate> TRIANGLE = List.of(
            new GpsCoordinate(new BigDecimal("28.1"), new BigDecimal("112.9")),
            new GpsCoordinate(new BigDecimal("28.2"), new BigDecimal("112.9")),
            new GpsCoordinate(new BigDecimal("28.2"), new BigDecimal("113.0")));

    @Test
    void createFence_withGenerationMetadata_serializesJsonOntoFence() throws Exception {
        when(fenceRepository.save(any(Fence.class))).thenAnswer(inv -> inv.getArgument(0));
        Map<String, Object> metadata = Map.of(
                "method", "DEVICE_TRACK",
                "deviceIds", List.of(101, 102),
                "usedPoints", 7412);

        FenceDto dto = service.createFence(new CreateFenceCommand(
                1L, "test", TRIANGLE, "#FF0000", null, metadata));

        ArgumentCaptor<Fence> captor = ArgumentCaptor.forClass(Fence.class);
        verify(fenceRepository).save(captor.capture());
        // Map.of iteration order is unspecified, so compare after a
        // JSON round-trip instead of asserting the raw string.
        Map<?, ?> stored = new com.fasterxml.jackson.databind.ObjectMapper()
                .readValue(captor.getValue().getGenerationMetadata(), Map.class);
        assertEquals(metadata, stored);
        // DTO echoes the metadata back as a Map.
        assertEquals(metadata, dto.generationMetadata());
    }

    @Test
    void createFence_withoutGenerationMetadata_staysNull() {
        when(fenceRepository.save(any(Fence.class))).thenAnswer(inv -> inv.getArgument(0));

        FenceDto dto = service.createFence(new CreateFenceCommand(
                1L, "test", TRIANGLE, "#FF0000", null, null));

        ArgumentCaptor<Fence> captor = ArgumentCaptor.forClass(Fence.class);
        verify(fenceRepository).save(captor.capture());
        assertNull(captor.getValue().getGenerationMetadata());
        assertNull(dto.generationMetadata());
    }
}
