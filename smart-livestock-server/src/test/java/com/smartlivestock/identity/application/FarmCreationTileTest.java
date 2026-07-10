package com.smartlivestock.identity.application;

import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.model.Coordinate;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.domain.port.RanchCommandPort;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataFarmRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FarmCreationTileTest {

    @Mock private FarmRepository farmRepository;
    @Mock private SpringDataFarmRepository persistenceContext;
    @Mock private TenantRepository tenantRepository;
    @Mock private UserRepository userRepository;
    @Mock private UserFarmAssignmentRepository assignmentRepository;
    @Mock private RanchCommandPort ranchCommandPort;

    @Test
    void createFarm_withBoundaryVertices_createsBoundaryFenceAndDetectsTiles() {
        when(tenantRepository.existsById(anyLong())).thenReturn(true);
        when(farmRepository.save(any(Farm.class))).thenAnswer(inv -> {
            Farm f = inv.getArgument(0);
            f.setId(1L);
            return f;
        });

        FarmApplicationService svc = new FarmApplicationService(farmRepository, persistenceContext,
                tenantRepository, userRepository, assignmentRepository, ranchCommandPort);

        List<Coordinate> vertices = List.of(
                new Coordinate(BigDecimal.valueOf(28.1), BigDecimal.valueOf(112.8)),
                new Coordinate(BigDecimal.valueOf(28.4), BigDecimal.valueOf(112.8)),
                new Coordinate(BigDecimal.valueOf(28.4), BigDecimal.valueOf(113.1))
        );
        CreateFarmCommand cmd = new CreateFarmCommand("测试牧场", BigDecimal.valueOf(28.2),
                BigDecimal.valueOf(113.0), BigDecimal.valueOf(100), vertices);

        FarmDto result = svc.createFarm(1L, cmd, null);

        assertNotNull(result);
        verify(ranchCommandPort).createBoundaryFenceAndDetectTiles(eq(1L), eq("测试牧场"),
                anyList(), anyList());
    }

    @Test
    void createFarm_withoutBoundaryVertices_skipsTileDetection() {
        when(tenantRepository.existsById(anyLong())).thenReturn(true);
        when(farmRepository.save(any(Farm.class))).thenAnswer(inv -> {
            Farm f = inv.getArgument(0);
            f.setId(1L);
            return f;
        });

        FarmApplicationService svc = new FarmApplicationService(farmRepository, persistenceContext,
                tenantRepository, userRepository, assignmentRepository, ranchCommandPort);

        CreateFarmCommand cmd = new CreateFarmCommand("测试牧场", BigDecimal.valueOf(28.2),
                BigDecimal.valueOf(113.0), BigDecimal.valueOf(100));

        FarmDto result = svc.createFarm(1L, cmd, null);

        assertNotNull(result);
        verifyNoInteractions(ranchCommandPort);
    }
}
