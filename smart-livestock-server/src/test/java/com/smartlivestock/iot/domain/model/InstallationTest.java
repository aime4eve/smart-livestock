package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class InstallationTest {

    private Installation createInstallation() {
        return new Installation(
            1L,     // deviceId
            100L,   // livestockId
            200L    // operatorId
        );
    }

    @Test
    void shouldInstallToDeviceAndLivestock() {
        Installation installation = createInstallation();

        assertThat(installation.getDeviceId()).isEqualTo(1L);
        assertThat(installation.getLivestockId()).isEqualTo(100L);
        assertThat(installation.getOperatorId()).isEqualTo(200L);
        assertThat(installation.getInstalledAt()).isNotNull();
        assertThat(installation.getRemovedAt()).isNull();
        assertThat(installation.isActive()).isTrue();
    }

    @Test
    void shouldRemoveInstallation() {
        Installation installation = createInstallation();

        installation.remove();

        assertThat(installation.getRemovedAt()).isNotNull();
        assertThat(installation.isActive()).isFalse();
    }

    @Test
    void shouldRejectRemoveAlreadyRemoved() {
        Installation installation = createInstallation();
        installation.remove();

        assertThatThrownBy(installation::remove)
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("already removed");
    }
}
