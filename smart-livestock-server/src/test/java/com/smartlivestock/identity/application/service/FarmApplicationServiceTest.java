package com.smartlivestock.identity.application.service;

import com.smartlivestock.identity.application.FarmApplicationService;
import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FarmApplicationServiceTest {

    @Mock private FarmRepository farmRepository;
    @Mock private UserRepository userRepository;
    @Mock private UserFarmAssignmentRepository assignmentRepository;

    @InjectMocks private FarmApplicationService farmApplicationService;

    @Test
    void shouldAutoAssignOwnerWhenCreatingFarm() {
        User owner = new User("owner", "hash", "牧场主", Role.OWNER, 1L);
        when(userRepository.findById(100L)).thenReturn(Optional.of(owner));
        when(farmRepository.save(any())).thenAnswer(inv -> {
            Farm f = inv.getArgument(0);
            f.setId(999L);
            return f;
        });
        when(assignmentRepository.existsByUserIdAndFarmId(eq(100L), anyLong())).thenReturn(false);

        CreateFarmCommand cmd = new CreateFarmCommand("新牧场", new BigDecimal("28.2458"), new BigDecimal("112.8519"), new BigDecimal("500"));

        FarmDto result = farmApplicationService.createFarm(1L, cmd, 100L);

        assertThat(result).isNotNull();
        verify(assignmentRepository).save(eq(100L), anyLong(), eq("OWNER"), eq("ACTIVE"));
    }

    @Test
    void shouldSkipAssignmentWhenUserIdIsNull() {
        CreateFarmCommand cmd = new CreateFarmCommand("新牧场", null, null, null);
        when(farmRepository.save(any())).thenAnswer(inv -> {
            Farm f = inv.getArgument(0);
            f.setId(999L);
            return f;
        });

        FarmDto result = farmApplicationService.createFarm(1L, cmd, null);

        assertThat(result).isNotNull();
        verify(assignmentRepository, never()).save(anyLong(), anyLong(), anyString(), anyString());
    }

    @Test
    void shouldSkipAssignmentWhenNotOwner() {
        User worker = new User("worker", "hash", "牧工", Role.WORKER, 1L);
        when(userRepository.findById(200L)).thenReturn(Optional.of(worker));
        when(farmRepository.save(any())).thenAnswer(inv -> {
            Farm f = inv.getArgument(0);
            f.setId(999L);
            return f;
        });

        CreateFarmCommand cmd = new CreateFarmCommand("新牧场", null, null, null);

        FarmDto result = farmApplicationService.createFarm(1L, cmd, 200L);

        assertThat(result).isNotNull();
        verify(assignmentRepository, never()).save(anyLong(), anyLong(), anyString(), anyString());
    }

    @Test
    void shouldSkipAssignmentWhenAlreadyAssigned() {
        User owner = new User("owner", "hash", "牧场主", Role.OWNER, 1L);
        when(userRepository.findById(100L)).thenReturn(Optional.of(owner));
        when(farmRepository.save(any())).thenAnswer(inv -> {
            Farm f = inv.getArgument(0);
            f.setId(999L);
            return f;
        });
        when(assignmentRepository.existsByUserIdAndFarmId(eq(100L), anyLong())).thenReturn(true);

        CreateFarmCommand cmd = new CreateFarmCommand("新牧场", null, null, null);

        FarmDto result = farmApplicationService.createFarm(1L, cmd, 100L);

        assertThat(result).isNotNull();
        verify(assignmentRepository, never()).save(anyLong(), anyLong(), anyString(), anyString());
    }
}
