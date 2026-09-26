package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.command.UpdateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.service.BufferPolygonCalculator;
import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FenceVersionTest {

    /** Valid triangle: NIX-213 vertex validation rejects <3-vertex fences before version logic. */
    private static final List<com.smartlivestock.ranch.domain.model.GpsCoordinate> TRIANGLE = List.of(
            new com.smartlivestock.ranch.domain.model.GpsCoordinate("28.20", "112.90"),
            new com.smartlivestock.ranch.domain.model.GpsCoordinate("28.21", "112.91"),
            new com.smartlivestock.ranch.domain.model.GpsCoordinate("28.19", "112.92"));

    @Mock
    private FenceRepository fenceRepository;

    @Test
    void updateFence_keepsVersion_whenExpectedMatches() {
        Fence fence = new Fence(1L, "test", TRIANGLE, "#FF0000");
        fence.setVersion(2);
        when(fenceRepository.findById(1L)).thenReturn(Optional.of(fence));
        when(fenceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        FenceApplicationService svc = new FenceApplicationService(fenceRepository,
                org.mockito.Mockito.mock(com.smartlivestock.ranch.domain.repository.AlertRepository.class),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.domain.repository.FenceZoneRepository.class),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.domain.repository.LivestockRepository.class),
                new BufferPolygonCalculator(),
                new com.smartlivestock.ranch.domain.service.FenceLivestockCounter(),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.application.signal.SignalRevisionService.class));
        FenceDto result = svc.updateFence(1L, new UpdateFenceCommand("up", TRIANGLE, "#00F", 2));
        assertEquals(2, result.version());
    }

    @Test
    void updateFence_rejectsStaleVersion() {
        Fence fence = new Fence(1L, "test", TRIANGLE, "#FF0000");
        fence.setVersion(5);
        when(fenceRepository.findById(1L)).thenReturn(Optional.of(fence));

        FenceApplicationService svc = new FenceApplicationService(fenceRepository,
                org.mockito.Mockito.mock(com.smartlivestock.ranch.domain.repository.AlertRepository.class),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.domain.repository.FenceZoneRepository.class),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.domain.repository.LivestockRepository.class),
                new BufferPolygonCalculator(),
                new com.smartlivestock.ranch.domain.service.FenceLivestockCounter(),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.application.signal.SignalRevisionService.class));
        assertThrows(ApiException.class,
            () -> svc.updateFence(1L, new UpdateFenceCommand("up", TRIANGLE, "#00F", 3)));
    }

    @Test
    void updateFence_skipsCheck_whenExpectedVersionNull() {
        Fence fence = new Fence(1L, "test", TRIANGLE, "#FF0000");
        fence.setVersion(5);
        when(fenceRepository.findById(1L)).thenReturn(Optional.of(fence));
        when(fenceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        FenceApplicationService svc = new FenceApplicationService(fenceRepository,
                org.mockito.Mockito.mock(com.smartlivestock.ranch.domain.repository.AlertRepository.class),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.domain.repository.FenceZoneRepository.class),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.domain.repository.LivestockRepository.class),
                new BufferPolygonCalculator(),
                new com.smartlivestock.ranch.domain.service.FenceLivestockCounter(),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.application.signal.SignalRevisionService.class));
        FenceDto result = svc.updateFence(1L, new UpdateFenceCommand("up", TRIANGLE, "#00F", null));
        assertEquals(5, result.version());
    }
}
