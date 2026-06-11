package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class AlertTest {

    private Alert createActiveAlert() {
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
    void shouldCreateActiveAlert() {
        Alert alert = createActiveAlert();

        assertThat(alert.getStatus()).isEqualTo(AlertStatus.ACTIVE);
        assertThat(alert.getFarmId()).isEqualTo(1L);
        assertThat(alert.getLivestockId()).isEqualTo(100L);
        assertThat(alert.getFenceId()).isEqualTo(10L);
        assertThat(alert.getType()).isEqualTo(AlertType.FENCE_BREACH);
        assertThat(alert.getSeverity()).isEqualTo(Severity.WARNING);
        assertThat(alert.getMessage()).isEqualTo("Livestock has breached the fence boundary");
        assertThat(alert.getResolvedType()).isNull();
        assertThat(alert.getResolvedAt()).isNull();
    }

    @Test
    void shouldTransitionActiveToDismissed() {
        Alert alert = createActiveAlert();

        alert.dismiss(200L);

        assertThat(alert.getStatus()).isEqualTo(AlertStatus.DISMISSED);
        assertThat(alert.getResolvedType()).isEqualTo("MANUAL_DISMISS");
        assertThat(alert.getResolvedAt()).isNotNull();
        assertThat(alert.getHandledBy()).isEqualTo(200L); // legacy compat
    }

    @Test
    void shouldTransitionActiveToAutoResolved() {
        Alert alert = createActiveAlert();

        alert.autoResolve();

        assertThat(alert.getStatus()).isEqualTo(AlertStatus.AUTO_RESOLVED);
        assertThat(alert.getResolvedType()).isEqualTo("AUTO");
        assertThat(alert.getResolvedAt()).isNotNull();
    }

    @Test
    void shouldAutoResolveBeIdempotent() {
        Alert alert = createActiveAlert();
        alert.autoResolve();

        // Second call should be no-op
        assertThatCode(() -> alert.autoResolve()).doesNotThrowAnyException();
        assertThat(alert.getStatus()).isEqualTo(AlertStatus.AUTO_RESOLVED);
    }

    @Test
    void shouldRejectDismissOnDismissed() {
        Alert alert = createActiveAlert();
        alert.dismiss(200L);

        assertThatThrownBy(() -> alert.dismiss(300L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("ACTIVE");
    }

    @Test
    void shouldRejectDismissOnAutoResolved() {
        Alert alert = createActiveAlert();
        alert.autoResolve();

        assertThatThrownBy(() -> alert.dismiss(300L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("ACTIVE");
    }
}
