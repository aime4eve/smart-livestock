package com.smartlivestock.identity.application.service;

import com.smartlivestock.identity.application.FarmApplicationService;
import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.domain.port.RanchCommandPort;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FarmApplicationServiceTest {

    @Mock private FarmRepository farmRepository;
    @Mock private com.smartlivestock.identity.infrastructure.persistence.SpringDataFarmRepository persistenceContext;
    @Mock private TenantRepository tenantRepository;
    @Mock private UserRepository userRepository;
    @Mock private UserFarmAssignmentRepository assignmentRepository;
    @Mock private RanchCommandPort ranchCommandPort;

    private FarmApplicationService service;

    @BeforeEach
    void setUp() {
        service = new FarmApplicationService(
                farmRepository, persistenceContext, tenantRepository, userRepository,
                assignmentRepository, ranchCommandPort
        );
    }

    @Test
    void shouldCreateFarmAndAutoAssignOwner() {
        when(tenantRepository.existsById(1L)).thenReturn(true);

        User owner = new User("hash", "牧场主", Role.OWNER, 1L);
        owner.setId(1L);
        when(userRepository.findById(1L)).thenReturn(Optional.of(owner));
        when(assignmentRepository.existsByUserIdAndFarmId(1L, 100L)).thenReturn(false);

        var farm = mock(com.smartlivestock.identity.domain.model.Farm.class);
        when(farm.getId()).thenReturn(100L);
        when(farmRepository.save(any())).thenReturn(farm);

        CreateFarmCommand cmd = new CreateFarmCommand("新牧场", BigDecimal.valueOf(28.0), BigDecimal.valueOf(112.0), BigDecimal.valueOf(100.0), null);
        FarmDto result = service.createFarm(1L, cmd, 1L);

        verify(assignmentRepository).save(1L, 100L, "OWNER", "ACTIVE");
    }

    @Test
    void shouldRejectCreateForNonexistentTenant() {
        when(tenantRepository.existsById(999L)).thenReturn(false);

        CreateFarmCommand cmd = new CreateFarmCommand("坏牧场", BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, null);
        assertThatThrownBy(() -> service.createFarm(999L, cmd, null))
                .isInstanceOf(ApiException.class)
                .extracting(e -> ((ApiException) e).getCode())
                .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND);
    }

    @Test
    void shouldNotAutoAssignWorker() {
        when(tenantRepository.existsById(1L)).thenReturn(true);

        User worker = new User("hash", "牧工", Role.WORKER, 1L);
        worker.setId(2L);
        when(userRepository.findById(2L)).thenReturn(Optional.of(worker));

        var farm = mock(com.smartlivestock.identity.domain.model.Farm.class);
        when(farm.getId()).thenReturn(101L);
        when(farmRepository.save(any())).thenReturn(farm);

        CreateFarmCommand cmd = new CreateFarmCommand("牧场2", BigDecimal.valueOf(28.0), BigDecimal.valueOf(112.0), BigDecimal.valueOf(100.0), null);
        service.createFarm(1L, cmd, 2L);

        verify(assignmentRepository, never()).save(anyLong(), anyLong(), anyString(), anyString());
    }

    @Test
    void shouldNotAutoAssignOwnerFromDifferentTenant() {
        when(tenantRepository.existsById(1L)).thenReturn(true);

        User owner = new User("hash", "牧场主", Role.OWNER, 999L);
        owner.setId(3L);
        when(userRepository.findById(3L)).thenReturn(Optional.of(owner));

        var farm = mock(com.smartlivestock.identity.domain.model.Farm.class);
        when(farm.getId()).thenReturn(102L);
        when(farmRepository.save(any())).thenReturn(farm);

        CreateFarmCommand cmd = new CreateFarmCommand("牧场3", BigDecimal.valueOf(28.0), BigDecimal.valueOf(112.0), BigDecimal.valueOf(100.0), null);
        service.createFarm(1L, cmd, 3L);

        verify(assignmentRepository, never()).save(anyLong(), anyLong(), anyString(), anyString());
    }
}
