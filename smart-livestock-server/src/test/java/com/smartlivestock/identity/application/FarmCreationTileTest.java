package com.smartlivestock.identity.application;

import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.ranch.application.TileAdminService;
import com.smartlivestock.ranch.application.dto.FarmTileStatusDto;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.service.TileCoverageCalculator;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FarmCreationTileTest {

    @Mock private FarmRepository farmRepository;
    @Mock private TenantRepository tenantRepository;
    @Mock private UserRepository userRepository;
    @Mock private UserFarmAssignmentRepository assignmentRepository;
    @Mock private FenceRepository fenceRepository;
    @Mock private TileAdminService tileAdminService;
    @Mock private TileCoverageCalculator coverageCalculator;

    @Test
    void createFarm_withBoundaryVertices_createsBoundaryFenceAndDetectsTiles() {
        when(tenantRepository.existsById(anyLong())).thenReturn(true);
        when(farmRepository.save(any(Farm.class))).thenAnswer(inv -> {
            Farm f = inv.getArgument(0);
            f.setId(1L);
            return f;
        });
        when(fenceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(coverageCalculator.calculateBbox(any())).thenReturn(new double[]{112.8, 28.1, 113.1, 28.4});
        when(coverageCalculator.coverageRatio(any())).thenReturn(0.85);
        when(tileAdminService.handleFarmTileDetection(eq(1L), any(double[].class), eq(0.85)))
                .thenReturn(new FarmTileStatusDto(1L, List.of(), 0.85, false));

        FarmApplicationService svc = new FarmApplicationService(farmRepository, tenantRepository,
                userRepository, assignmentRepository, fenceRepository, tileAdminService, coverageCalculator);

        List<GpsCoordinate> vertices = List.of(
                new GpsCoordinate(BigDecimal.valueOf(28.1), BigDecimal.valueOf(112.8)),
                new GpsCoordinate(BigDecimal.valueOf(28.4), BigDecimal.valueOf(112.8)),
                new GpsCoordinate(BigDecimal.valueOf(28.4), BigDecimal.valueOf(113.1))
        );
        CreateFarmCommand cmd = new CreateFarmCommand("测试牧场", BigDecimal.valueOf(28.2),
                BigDecimal.valueOf(113.0), BigDecimal.valueOf(100), vertices);

        FarmDto result = svc.createFarm(1L, cmd, null);

        assertNotNull(result);
        verify(fenceRepository).save(argThat(fence ->
                "boundary".equals(fence.getFenceType()) &&
                fence.getName().contains("边界")));
        verify(tileAdminService).handleFarmTileDetection(eq(1L), any(double[].class), eq(0.85));
    }

    @Test
    void createFarm_withoutBoundaryVertices_skipsTileDetection() {
        when(tenantRepository.existsById(anyLong())).thenReturn(true);
        when(farmRepository.save(any(Farm.class))).thenAnswer(inv -> {
            Farm f = inv.getArgument(0);
            f.setId(1L);
            return f;
        });

        FarmApplicationService svc = new FarmApplicationService(farmRepository, tenantRepository,
                userRepository, assignmentRepository, fenceRepository, tileAdminService, coverageCalculator);

        CreateFarmCommand cmd = new CreateFarmCommand("测试牧场", BigDecimal.valueOf(28.2),
                BigDecimal.valueOf(113.0), BigDecimal.valueOf(100));

        FarmDto result = svc.createFarm(1L, cmd, null);

        assertNotNull(result);
        verifyNoInteractions(fenceRepository, tileAdminService, coverageCalculator);
    }
}
