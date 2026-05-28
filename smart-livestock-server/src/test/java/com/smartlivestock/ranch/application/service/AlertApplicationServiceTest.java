package com.smartlivestock.ranch.application.service;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.command.AcknowledgeAlertCommand;
import com.smartlivestock.ranch.application.command.ArchiveAlertCommand;
import com.smartlivestock.ranch.application.command.HandleAlertCommand;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit-level integration test for AlertApplicationService.
 * <p>
 * Tests the alert state machine (PENDING -> ACKNOWLEDGED -> HANDLED -> ARCHIVED)
 * through the application service layer with mocked repository.
 */
@ExtendWith(MockitoExtension.class)
class AlertApplicationServiceTest {

    @Mock
    private AlertRepository alertRepository;

    @InjectMocks
    private AlertApplicationService service;

    private Alert createPendingAlert() {
        Alert alert = new Alert(1L, 100L, 10L, AlertType.FENCE_BREACH, Severity.WARNING, "牛只越出围栏");
        alert.setId(1L);
        return alert;
    }

    private Alert createAcknowledgedAlert() {
        Alert alert = createPendingAlert();
        alert.acknowledge(1L);
        return alert;
    }

    private Alert createHandledAlert() {
        Alert alert = createAcknowledgedAlert();
        alert.handle(1L);
        return alert;
    }

    @Test
    @DisplayName("创建新告警")
    void shouldCreateAlert() {
        when(alertRepository.save(any(Alert.class))).thenAnswer(inv -> {
            Alert a = inv.getArgument(0);
            a.setId(1L);
            return a;
        });

        AlertDto result = service.createAlert(1L, AlertType.FENCE_BREACH, Severity.WARNING, "牛只越出围栏");

        assertThat(result.type()).isEqualTo("FENCE_BREACH");
        assertThat(result.severity()).isEqualTo("WARNING");
        assertThat(result.status()).isEqualTo("PENDING");
        assertThat(result.message()).isEqualTo("牛只越出围栏");
        assertThat(result.farmId()).isEqualTo(1L);

        ArgumentCaptor<Alert> captor = ArgumentCaptor.forClass(Alert.class);
        verify(alertRepository).save(captor.capture());
        Alert saved = captor.getValue();
        assertThat(saved.getStatus()).isEqualTo(AlertStatus.PENDING);
    }

    @Test
    @DisplayName("确认待处理告警")
    void shouldAcknowledgePendingAlert() {
        Alert alert = createPendingAlert();
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(alertRepository.save(any(Alert.class))).thenAnswer(inv -> inv.getArgument(0));

        AlertDto result = service.acknowledge(new AcknowledgeAlertCommand(1L, 1L));

        assertThat(result.status()).isEqualTo("ACKNOWLEDGED");
        assertThat(result.acknowledgedBy()).isEqualTo(1L);

        ArgumentCaptor<Alert> captor = ArgumentCaptor.forClass(Alert.class);
        verify(alertRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(AlertStatus.ACKNOWLEDGED);
    }

    @Test
    @DisplayName("处理已确认告警")
    void shouldHandleAcknowledgedAlert() {
        Alert alert = createAcknowledgedAlert();
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(alertRepository.save(any(Alert.class))).thenAnswer(inv -> inv.getArgument(0));

        AlertDto result = service.handle(new HandleAlertCommand(1L, 1L));

        assertThat(result.status()).isEqualTo("HANDLED");
        assertThat(result.handledBy()).isEqualTo(1L);

        ArgumentCaptor<Alert> captor = ArgumentCaptor.forClass(Alert.class);
        verify(alertRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(AlertStatus.HANDLED);
    }

    @Test
    @DisplayName("归档已处理告警")
    void shouldArchiveHandledAlert() {
        Alert alert = createHandledAlert();
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(alertRepository.save(any(Alert.class))).thenAnswer(inv -> inv.getArgument(0));

        AlertDto result = service.archive(new ArchiveAlertCommand(1L, 1L));

        assertThat(result.status()).isEqualTo("ARCHIVED");
    }

    @Test
    @DisplayName("拒绝无效状态转换: 直接处理 PENDING 告警")
    void shouldRejectHandleOnPendingAlert() {
        Alert alert = createPendingAlert();
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));

        assertThatThrownBy(() -> service.handle(new HandleAlertCommand(1L, 1L)))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                });
    }

    @Test
    @DisplayName("拒绝无效状态转换: 归档 ACKNOWLEDGED 告警")
    void shouldRejectArchiveOnAcknowledgedAlert() {
        Alert alert = createAcknowledgedAlert();
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));

        assertThatThrownBy(() -> service.archive(new ArchiveAlertCommand(1L, 1L)))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                });
    }

    @Test
    @DisplayName("拒绝无效状态转换: 确认已处理告警")
    void shouldRejectAcknowledgeOnHandledAlert() {
        Alert alert = createHandledAlert();
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));

        assertThatThrownBy(() -> service.acknowledge(new AcknowledgeAlertCommand(1L, 1L)))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                });
    }

    @Test
    @DisplayName("告警不存在时，抛出 RESOURCE_NOT_FOUND")
    void shouldThrowResourceNotFoundForMissingAlert() {
        when(alertRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.acknowledge(new AcknowledgeAlertCommand(999L, 1L)))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND);
                });
    }
}
