package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.*;

class AlertTest {

    private Alert createPendingAlert() {
        return new Alert(
            1L, // farmId
            100L, // livestockId
            10L, // fenceId
            AlertType.FENCE_BREACH,
            Severity.WARNING,
            "Livestock has breached the fence boundary"
        );
    }

    @Test
    void shouldCreatePendingAlert() {
        Alert alert = createPendingAlert();

        assertThat(alert.getStatus()).isEqualTo(AlertStatus.PENDING);
        assertThat(alert.getFarmId()).isEqualTo(1L);
        assertThat(alert.getLivestockId()).isEqualTo(100L);
        assertThat(alert.getFenceId()).isEqualTo(10L);
        assertThat(alert.getType()).isEqualTo(AlertType.FENCE_BREACH);
        assertThat(alert.getSeverity()).isEqualTo(Severity.WARNING);
        assertThat(alert.getMessage()).isEqualTo("Livestock has breached the fence boundary");
        assertThat(alert.getAcknowledgedBy()).isNull();
        assertThat(alert.getAcknowledgedAt()).isNull();
        assertThat(alert.getHandledBy()).isNull();
        assertThat(alert.getHandledAt()).isNull();
    }

    @Test
    void shouldTransitionPendingToAcknowledged() {
        Alert alert = createPendingAlert();

        alert.acknowledge(200L);

        assertThat(alert.getStatus()).isEqualTo(AlertStatus.ACKNOWLEDGED);
        assertThat(alert.getAcknowledgedBy()).isEqualTo(200L);
        assertThat(alert.getAcknowledgedAt()).isNotNull();
    }

    @Test
    void shouldTransitionAcknowledgedToHandled() {
        Alert alert = createPendingAlert();
        alert.acknowledge(200L);

        alert.handle(300L);

        assertThat(alert.getStatus()).isEqualTo(AlertStatus.HANDLED);
        assertThat(alert.getHandledBy()).isEqualTo(300L);
        assertThat(alert.getHandledAt()).isNotNull();
    }

    @Test
    void shouldTransitionHandledToArchived() {
        Alert alert = createPendingAlert();
        alert.acknowledge(200L);
        alert.handle(300L);

        alert.archive(200L);

        assertThat(alert.getStatus()).isEqualTo(AlertStatus.ARCHIVED);
    }

    @Test
    void shouldRejectAcknowledgeTwice() {
        Alert alert = createPendingAlert();
        alert.acknowledge(200L);

        assertThatThrownBy(() -> alert.acknowledge(300L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("pending");
    }

    @Test
    void shouldRejectHandleOnPending() {
        Alert alert = createPendingAlert();

        assertThatThrownBy(() -> alert.handle(300L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("acknowledged");
    }

    @Test
    void shouldRejectArchiveOnNonHandled() {
        Alert alert = createPendingAlert();
        alert.acknowledge(200L);

        assertThatThrownBy(() -> alert.archive(200L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("handled");
    }
}
