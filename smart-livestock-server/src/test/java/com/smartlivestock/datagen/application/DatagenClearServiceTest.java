package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.DatagenOperatorContext.DatagenOperatorRole;
import com.smartlivestock.datagen.application.dto.DatagenClearRequest;
import com.smartlivestock.datagen.application.dto.DatagenClearResultDto;
import com.smartlivestock.datagen.domain.model.DatagenFarmControl;
import com.smartlivestock.datagen.domain.repository.DatagenFarmControlRepository;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DatagenClearServiceTest {
    @Mock private FarmRepository farmRepository;
    @Mock private DatagenOperatorContextResolver operatorResolver;
    @Mock private DatagenFarmControlRepository controlRepository;
    @Mock private DatagenDataQueryService dataQueryService;
    @Mock private DatagenAuditService auditService;

    @InjectMocks
    private DatagenFarmAccessService accessService;

    private DatagenClearService service;

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        service = new DatagenClearService(
                accessService, operatorResolver, controlRepository,
                dataQueryService, auditService);
    }

    @Test
    void clear_runningFarm_rejectsWithoutDeleting() {
        prepareFarmAndOperator();
        DatagenFarmControl control = control(1L, true);
        when(controlRepository.findByFarmId(1L)).thenReturn(Optional.of(control));
        when(controlRepository.lockByFarmId(1L)).thenReturn(Optional.of(control));

        ApiException ex = assertThrows(ApiException.class,
                () -> service.clear(request("LAST_24_HOURS", "清空")));
        assertEquals(ErrorCode.STATE_CONFLICT, ex.getCode());
        verifyNoInteractions(dataQueryService, auditService);
    }

    @Test
    void clear_wrongConfirmText_rejectsBeforeLocking() {
        prepareFarmAndOperator();

        ApiException ex = assertThrows(ApiException.class,
                () -> service.clear(request("LAST_24_HOURS", "delete")));
        assertEquals(ErrorCode.VALIDATION_ERROR, ex.getCode());
        verifyNoInteractions(controlRepository, dataQueryService, auditService);
    }

    @Test
    void clear_stoppedFarm_clearsAndWritesAudit() {
        prepareFarmAndOperator();
        DatagenFarmControl control = control(1L, false);
        when(controlRepository.findByFarmId(1L)).thenReturn(Optional.of(control));
        when(controlRepository.lockByFarmId(1L)).thenReturn(Optional.of(control));
        DatagenClearResultDto result = result(1, 2, 3, 4, 5, 6, 7, 8);
        when(dataQueryService.clear(eq(1L), any(Instant.class), any(Instant.class)))
                .thenReturn(result);

        DatagenClearResultDto actual = service.clear(request("LAST_24_HOURS", "清空"));

        assertEquals(result, actual);
        verify(auditService).record(
                eq("CLEAR_DATA"), eq(1L), any(DatagenOperatorContext.class), any());
    }

    @Test
    void clear_invalidCustomRange_rejects() {
        prepareFarmAndOperator();
        Instant now = Instant.now();
        ApiException ex = assertThrows(ApiException.class,
                () -> service.clear(new DatagenClearRequest(
                        1L, "CUSTOM", now, now.minusSeconds(1), "清空")));
        assertEquals(ErrorCode.VALIDATION_ERROR, ex.getCode());
        verifyNoInteractions(dataQueryService, auditService);
    }

    private void prepareFarmAndOperator() {
        Farm farm = new Farm();
        farm.setId(1L);
        farm.setTenantId(1L);
        when(farmRepository.findById(1L)).thenReturn(Optional.of(farm));
        when(operatorResolver.resolve()).thenReturn(new DatagenOperatorContext(
                3L, 1L, DatagenOperatorRole.PLATFORM_ADMIN));
    }

    private DatagenClearRequest request(String rangeType, String confirmText) {
        return new DatagenClearRequest(1L, rangeType, null, null, confirmText);
    }

    private DatagenFarmControl control(Long id, boolean enabled) {
        DatagenFarmControl control = new DatagenFarmControl();
        control.setId(id);
        control.setFarmId(1L);
        control.setTenantId(1L);
        control.setScenarioId(1L);
        control.setEnabled(enabled);
        return control;
    }

    private DatagenClearResultDto result(
            long telemetry, long gps, long temperature, long motility,
            long activity, long estrus, long anomaly, long alerts) {
        return new DatagenClearResultDto(
                telemetry, gps, temperature, motility, activity, estrus, anomaly,
                alerts, 0, 0, "datagenConsoleCrossFarmLimit");
    }
}
