package com.smartlivestock.ranch.application.service;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AlertApplicationServiceTest {

    @Mock
    private AlertRepository alertRepository;

    @Mock
    private SpringDataAlertReadStatusRepository readStatusRepository;

    @InjectMocks
    private AlertApplicationService service;

    private Alert createActiveAlert() {
        Alert alert = new Alert(1L, 100L, 10L, AlertType.FENCE_BREACH, Severity.WARNING, "牛只越出围栏");
        alert.setId(1L);
        return alert;
    }

    @Test
    @DisplayName("创建新告警 — 默认 ACTIVE")
    void shouldCreateAlert() {
        when(alertRepository.save(any(Alert.class))).thenAnswer(inv -> {
            Alert a = inv.getArgument(0);
            a.setId(1L);
            return a;
        });

        AlertDto result = service.createAlert(1L, AlertType.FENCE_BREACH, Severity.WARNING, "牛只越出围栏");

        assertThat(result.type()).isEqualTo("FENCE_BREACH");
        assertThat(result.status()).isEqualTo("ACTIVE");
        assertThat(result.farmId()).isEqualTo(1L);
    }

    @Test
    @DisplayName("忽略 ACTIVE 告警 → DISMISSED")
    void shouldDismissActiveAlert() {
        Alert alert = createActiveAlert();
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(alertRepository.save(any(Alert.class))).thenAnswer(inv -> inv.getArgument(0));

        AlertDto result = service.dismiss(1L, 1L);

        assertThat(result.status()).isEqualTo("DISMISSED");
        assertThat(result.resolvedType()).isEqualTo("MANUAL_DISMISS");
    }

    @Test
    @DisplayName("自动解除 ACTIVE 告警 → AUTO_RESOLVED")
    void shouldAutoResolveActiveAlert() {
        Alert alert = createActiveAlert();
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(alertRepository.save(any(Alert.class))).thenAnswer(inv -> inv.getArgument(0));

        AlertDto result = service.autoResolve(1L);

        assertThat(result.status()).isEqualTo("AUTO_RESOLVED");
        assertThat(result.resolvedType()).isEqualTo("AUTO");
    }

    @Test
    @DisplayName("markRead 调用 readStatusRepository")
    void shouldMarkRead() {
        Alert alert = createActiveAlert();
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(readStatusRepository.existsByAlertIdAndUserId(1L, 200L)).thenReturn(true);

        AlertDto result = service.markRead(1L, 200L);

        assertThat(result.read()).isTrue();
        verify(readStatusRepository).insertOnConflictDoNothing(1L, 200L);
    }

    @Test
    @DisplayName("拒绝忽略已解除的告警")
    void shouldRejectDismissOnDismissedAlert() {
        Alert alert = createActiveAlert();
        alert.dismiss(1L);
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));

        assertThatThrownBy(() -> service.dismiss(1L, 1L))
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

        assertThatThrownBy(() -> service.dismiss(999L, 1L))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND);
                });
    }
}
