package com.smartlivestock.ranch.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.dto.AlertSummaryDto.AlertSummaryResponse;
import com.smartlivestock.ranch.application.service.AlertMessageLocalizer;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import com.smartlivestock.shared.cache.RedisCacheService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the alert summary aggregation (GET /alerts/summary).
 * Verifies the reconciliation invariant: critical+warning+info ≡ active total.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AlertSummaryTest {

    @Mock
    private AlertRepository alertRepository;

    @Mock
    private SpringDataAlertReadStatusRepository readStatusRepository;

    @Mock
    private AlertMessageLocalizer alertMessageLocalizer;

    @Mock
    private IoTQueryPort ioTQueryPort;

    @Mock
    private RedisCacheService redisCacheService;

    private AlertApplicationService service;

    @BeforeEach
    void setUp() {
        // Real ObjectMapper: the summary is serialized into the Redis cache
        service = new AlertApplicationService(
                alertRepository, readStatusRepository, alertMessageLocalizer,
                ioTQueryPort, redisCacheService, new ObjectMapper());
    }

    @Test
    @DisplayName("分组计数映射正确，且 严重+警告+提示 ≡ 活跃总数")
    void summaryMapping_andReconciliation() {
        when(alertRepository.countByFarmGrouped(1L, List.of())).thenReturn(List.of(
                new AlertRepository.StatusSeverityTypeCount("ACTIVE", "CRITICAL", "FENCE_BREACH", 13),
                new AlertRepository.StatusSeverityTypeCount("ACTIVE", "WARNING", "TEMPERATURE_ABNORMAL", 1),
                new AlertRepository.StatusSeverityTypeCount("ACTIVE", "INFO", "ESTRUS", 2),
                new AlertRepository.StatusSeverityTypeCount("ACTIVE", "WARNING", "DEVICE_LOW_BATTERY", 4),
                new AlertRepository.StatusSeverityTypeCount("AUTO_RESOLVED", "CRITICAL", "FENCE_BREACH", 100),
                new AlertRepository.StatusSeverityTypeCount("DISMISSED", "WARNING", "TEMPERATURE_ABNORMAL", 23)
        ));
        when(alertRepository.countActiveUnreadGroupedByType(1L, 200L, List.of())).thenReturn(List.of(
                new AlertRepository.TypeCount("FENCE_BREACH", 2),
                new AlertRepository.TypeCount("TEMPERATURE_ABNORMAL", 1)
        ));

        AlertSummaryResponse summary = service.getAlertSummary(1L, 200L, List.of());

        assertThat(summary.active().total()).isEqualTo(20);
        assertThat(summary.active().critical()).isEqualTo(13);
        assertThat(summary.active().warning()).isEqualTo(5);
        assertThat(summary.active().info()).isEqualTo(2);
        // reconciliation invariant
        assertThat(summary.active().critical()
                + summary.active().warning()
                + summary.active().info()).isEqualTo(summary.active().total());

        assertThat(summary.active().byGroup().fence()).isEqualTo(13);
        assertThat(summary.active().byGroup().health()).isEqualTo(3);
        assertThat(summary.active().byGroup().device()).isEqualTo(4);

        assertThat(summary.active().unread()).isEqualTo(3);
        assertThat(summary.active().byGroupUnread().fence()).isEqualTo(2);
        assertThat(summary.active().byGroupUnread().health()).isEqualTo(1);
        assertThat(summary.active().byGroupUnread().device()).isZero();

        assertThat(summary.resolved()).isEqualTo(123);
    }

    @Test
    @DisplayName("空牧场：全 0 且加总恒等式成立")
    void emptyFarm_allZero() {
        when(alertRepository.countByFarmGrouped(1L, List.of())).thenReturn(List.of());
        when(alertRepository.countActiveUnreadGroupedByType(1L, 200L, List.of())).thenReturn(List.of());

        AlertSummaryResponse summary = service.getAlertSummary(1L, 200L, List.of());

        assertThat(summary.active().total()).isZero();
        assertThat(summary.active().unread()).isZero();
        assertThat(summary.resolved()).isZero();
        assertThat(summary.active().critical()
                + summary.active().warning()
                + summary.active().info()).isZero();
    }

    @Test
    @DisplayName("结果写入 10s 缓存")
    void cachesResult() {
        when(alertRepository.countByFarmGrouped(1L, List.of())).thenReturn(List.of());
        when(alertRepository.countActiveUnreadGroupedByType(1L, 200L, List.of())).thenReturn(List.of());

        service.getAlertSummary(1L, 200L, List.of());

        verify(redisCacheService).set(
                eq("alerts:summary:1:200:all"), anyString(), eq(java.time.Duration.ofSeconds(10)));
    }

    @Test
    @DisplayName("markRead 后失效该用户的 summary 缓存")
    void markRead_evictsSummaryCache() {
        com.smartlivestock.ranch.domain.model.Alert alert =
                new com.smartlivestock.ranch.domain.model.Alert(
                        1L, 100L, 10L, AlertType.FENCE_BREACH, Severity.WARNING, "test");
        alert.setId(1L);
        when(alertRepository.findById(1L)).thenReturn(java.util.Optional.of(alert));

        service.markRead(1L, 200L);

        verify(redisCacheService).delete("alerts:summary:1:200:all");
        assertThat(alert.getStatus()).isEqualTo(AlertStatus.ACTIVE); // unchanged by read
    }
}
