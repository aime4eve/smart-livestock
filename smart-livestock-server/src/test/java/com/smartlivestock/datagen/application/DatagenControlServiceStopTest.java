package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.DatagenOperatorContext.DatagenOperatorRole;
import com.smartlivestock.datagen.application.dto.DatagenControlRequest;
import com.smartlivestock.datagen.application.dto.DatagenControlResponse;
import com.smartlivestock.datagen.domain.model.DatagenDeviceAssignment;
import com.smartlivestock.datagen.domain.model.DatagenFarmControl;
import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import com.smartlivestock.datagen.domain.repository.DatagenDeviceAssignmentRepository;
import com.smartlivestock.datagen.domain.repository.DatagenFarmControlRepository;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DatagenControlServiceStopTest {
    @Mock private FarmRepository farmRepository;
    @Mock private TenantRepository tenantRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private DeviceRepository deviceRepository;
    @Mock private InstallationRepository installationRepository;
    @Mock private LivestockRepository livestockRepository;
    @Mock private SynthesisScenarioRepository scenarioRepository;
    @Mock private DatagenFarmControlRepository controlRepository;
    @Mock private DatagenDeviceAssignmentRepository assignmentRepository;
    @Mock private DatagenFarmAccessService accessService;
    @Mock private DatagenOperatorContextResolver operatorResolver;
    @Mock private DatagenDataQueryService dataQueryService;
    @Mock private DatagenAuditService auditService;
    @Mock private SynthesisService synthesisService;

    private DatagenControlService service;

    @BeforeEach
    void setUp() {
        service = new DatagenControlService(
                farmRepository, tenantRepository, auditLogRepository,
                deviceRepository, installationRepository, livestockRepository,
                scenarioRepository, controlRepository, assignmentRepository,
                accessService, operatorResolver, dataQueryService, auditService,
                synthesisService);
    }

    @Test
    void stop_deactivatesActiveAssignmentsWithoutValidatingStaleDevices() {
        prepare();
        DatagenDeviceAssignment stale = assignment(113L);
        DatagenDeviceAssignment active = assignment(51L);
        when(assignmentRepository.findByControlId(9L)).thenReturn(List.of(stale, active));

        DatagenControlResponse response = service.updateControl(
                1L, new DatagenControlRequest(false, List.of(113L)));

        assertFalse(response.enabled());
        assertFalse(stale.isActive());
        assertFalse(active.isActive());
        verify(controlRepository).save(control());
        verify(assignmentRepository).saveAll(List.of(stale, active));
        verify(auditService).record(eq("STOP"), eq(1L), any(), any());
    }

    @Test
    void stop_emptyRequestDeactivatesAllActiveAssignments() {
        prepare();
        DatagenDeviceAssignment active = assignment(51L);
        when(assignmentRepository.findByControlId(9L)).thenReturn(List.of(active));

        service.updateControl(1L, new DatagenControlRequest(false, null));

        assertFalse(active.isActive());
        verify(auditService).record(eq("STOP"), eq(1L), any(), any());
    }

    @Test
    void enable_stillValidatesRequestedDevices() {
        prepare();

        assertThrows(ApiException.class, () -> service.updateControl(
                1L, new DatagenControlRequest(true, List.of())));
    }

    private void prepare() {
        Farm farm = new Farm();
        farm.setId(1L);
        farm.setTenantId(2L);
        DatagenOperatorContext operator = new DatagenOperatorContext(
                3L, null, DatagenOperatorRole.PLATFORM_ADMIN);
        when(operatorResolver.resolve()).thenReturn(operator);
        when(accessService.requireAccessibleFarm(1L, operator)).thenReturn(farm);
        SynthesisScenario scenario = new SynthesisScenario();
        scenario.setId(4L);
        scenario.setName("默认持续合成");
        scenario.setType(ScenarioType.NORMAL);
        scenario.setStatus(ScenarioStatus.RUNNING);
        scenario.setPenetrationRate(1.0);
        scenario.setWindowStart(Instant.now().minusSeconds(60));
        scenario.setWindowEnd(Instant.now().plusSeconds(3600));
        scenario.setIntervalSeconds(30);
        when(scenarioRepository.findFirstByNameOrderById("默认持续合成"))
                .thenReturn(Optional.of(scenario));
        when(scenarioRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(controlRepository.ensureByFarmId(2L, 1L, 4L)).thenReturn(control());
    }

    private DatagenFarmControl control() {
        DatagenFarmControl control = new DatagenFarmControl();
        control.setId(9L);
        control.setTenantId(2L);
        control.setFarmId(1L);
        control.setScenarioId(4L);
        control.enable();
        return control;
    }

    private DatagenDeviceAssignment assignment(Long deviceId) {
        DatagenDeviceAssignment assignment = new DatagenDeviceAssignment();
        assignment.setControlId(9L);
        assignment.setDeviceId(deviceId);
        assignment.setFirstAssignedAt(Instant.now());
        return assignment;
    }
}
