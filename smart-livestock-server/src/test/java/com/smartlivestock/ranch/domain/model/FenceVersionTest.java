package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.command.UpdateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
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

    @Mock
    private FenceRepository fenceRepository;

    @Test
    void updateFence_incrementsVersion() {
        Fence fence = new Fence(1L, "test", List.of(), "#FF0000");
        fence.setVersion(2);
        when(fenceRepository.findById(1L)).thenReturn(Optional.of(fence));
        when(fenceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        FenceApplicationService svc = new FenceApplicationService(fenceRepository);
        FenceDto result = svc.updateFence(1L, new UpdateFenceCommand("up", List.of(), "#00F", 2));
        assertEquals(3, result.version());
    }

    @Test
    void updateFence_rejectsStaleVersion() {
        Fence fence = new Fence(1L, "test", List.of(), "#FF0000");
        fence.setVersion(5);
        when(fenceRepository.findById(1L)).thenReturn(Optional.of(fence));

        FenceApplicationService svc = new FenceApplicationService(fenceRepository);
        assertThrows(ApiException.class,
            () -> svc.updateFence(1L, new UpdateFenceCommand("up", List.of(), "#00F", 3)));
    }

    @Test
    void updateFence_skipsCheck_whenExpectedVersionNull() {
        Fence fence = new Fence(1L, "test", List.of(), "#FF0000");
        fence.setVersion(5);
        when(fenceRepository.findById(1L)).thenReturn(Optional.of(fence));
        when(fenceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        FenceApplicationService svc = new FenceApplicationService(fenceRepository);
        FenceDto result = svc.updateFence(1L, new UpdateFenceCommand("up", List.of(), "#00F", null));
        assertEquals(6, result.version());
    }
}
