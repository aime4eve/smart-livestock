package com.smartlivestock.ranch.application.service;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for per-user read status tracking (alert_read_status).
 */
@ExtendWith(MockitoExtension.class)
class AlertReadStatusTest {

    @Mock
    private AlertRepository alertRepository;

    @Mock
    private SpringDataAlertReadStatusRepository readStatusRepository;

    @InjectMocks
    private AlertApplicationService service;

    private Alert createActiveAlert(Long id) {
        Alert alert = new Alert(1L, 100L, 10L, AlertType.FENCE_BREACH, Severity.WARNING, "test");
        alert.setId(id);
        return alert;
    }

    @Test
    @DisplayName("markRead — 首次标记，写入 read_status，返回 read=true")
    void markRead_firstTime_writesStatus() {
        Alert alert = createActiveAlert(1L);
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(readStatusRepository.existsByAlertIdAndUserId(1L, 200L)).thenReturn(true);

        AlertDto result = service.markRead(1L, 200L);

        assertThat(result.read()).isTrue();
        verify(readStatusRepository).insertOnConflictDoNothing(1L, 200L);
    }

    @Test
    @DisplayName("markRead — 重复标记幂等（ON CONFLICT DO NOTHING），仍返回 read=true")
    void markRead_idempotent() {
        Alert alert = createActiveAlert(1L);
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(readStatusRepository.existsByAlertIdAndUserId(1L, 200L)).thenReturn(true);

        AlertDto result = service.markRead(1L, 200L);

        assertThat(result.read()).isTrue();
        verify(readStatusRepository).insertOnConflictDoNothing(1L, 200L);
    }

    @Test
    @DisplayName("batchRead — 批量标记已读，返回正确计数")
    void batchRead_multipleAlerts() {
        when(alertRepository.findById(1L)).thenReturn(Optional.of(createActiveAlert(1L)));
        when(alertRepository.findById(2L)).thenReturn(Optional.of(createActiveAlert(2L)));
        when(alertRepository.findById(3L)).thenReturn(Optional.of(createActiveAlert(3L)));

        int count = service.batchRead(List.of(1L, 2L, 3L), 200L);

        assertThat(count).isEqualTo(3);
        verify(readStatusRepository).insertOnConflictDoNothing(1L, 200L);
        verify(readStatusRepository).insertOnConflictDoNothing(2L, 200L);
        verify(readStatusRepository).insertOnConflictDoNothing(3L, 200L);
    }

    @Test
    @DisplayName("batchRead — 跳过不存在的 alertId")
    void batchRead_skipsMissing() {
        when(alertRepository.findById(1L)).thenReturn(Optional.of(createActiveAlert(1L)));
        when(alertRepository.findById(999L)).thenReturn(Optional.empty());

        int count = service.batchRead(List.of(1L, 999L), 200L);

        assertThat(count).isEqualTo(1);
        verify(readStatusRepository).insertOnConflictDoNothing(1L, 200L);
        verify(readStatusRepository, never()).insertOnConflictDoNothing(eq(999L), any());
    }

    @Test
    @DisplayName("listByFarmWithReadStatus — 正确填充 read 字段（多用户隔离）")
    void listWithReadStatus_multiUserIsolation() {
        Alert alert1 = createActiveAlert(1L);
        Alert alert2 = createActiveAlert(2L);
        when(alertRepository.findByFarmId(1L)).thenReturn(List.of(alert1, alert2));
        // User 200 has read alert 1 but not alert 2
        when(readStatusRepository.findReadAlertIdsByUserId(eq(200L), anyCollection()))
                .thenReturn(Set.of(1L));

        List<AlertDto> result = service.listByFarmWithReadStatus(1L, 200L);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).read()).isTrue();   // alert 1 read by user 200
        assertThat(result.get(1).read()).isFalse();  // alert 2 not read by user 200
    }

    @Test
    @DisplayName("getAlertWithReadStatus — 单条查询正确返回 read 状态")
    void getWithReadStatus() {
        Alert alert = createActiveAlert(1L);
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(readStatusRepository.existsByAlertIdAndUserId(1L, 200L)).thenReturn(true);

        AlertDto result = service.getAlertWithReadStatus(1L, 200L);

        assertThat(result.read()).isTrue();
    }

    @Test
    @DisplayName("getAlertWithReadStatus — 未读返回 false")
    void getWithReadStatus_unread() {
        Alert alert = createActiveAlert(1L);
        when(alertRepository.findById(1L)).thenReturn(Optional.of(alert));
        when(readStatusRepository.existsByAlertIdAndUserId(1L, 300L)).thenReturn(false);

        AlertDto result = service.getAlertWithReadStatus(1L, 300L);

        assertThat(result.read()).isFalse();
    }

    @Test
    @DisplayName("listByFarmWithReadStatus — 空列表直接返回空")
    void listWithReadStatus_emptyFarm() {
        when(alertRepository.findByFarmId(99L)).thenReturn(List.of());

        List<AlertDto> result = service.listByFarmWithReadStatus(99L, 200L);

        assertThat(result).isEmpty();
        verify(readStatusRepository, never()).findReadAlertIdsByUserId(any(), any());
    }
}
