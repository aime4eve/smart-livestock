package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.GpsLogApplicationService;
import com.smartlivestock.iot.application.InstallationApplicationService;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GpsLogControllerTest {

    @Mock
    private GpsLogApplicationService gpsLogApplicationService;

    @Mock
    private InstallationApplicationService installationApplicationService;

    @Mock
    private DeviceApplicationService deviceApplicationService;

    @InjectMocks
    private GpsLogController controller;

    @Test
    void getDeviceGpsHistory_rejectsCapsule() {
        when(deviceApplicationService.getDevice(7L)).thenReturn(device(DeviceType.CAPSULE));

        assertThatThrownBy(() -> controller.getDeviceGpsHistory(1L, 7L, null, null, null))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                    assertThat(apiEx.getMessage()).isEqualTo("error.deviceGpsUnsupported");
                });

        verifyNoInteractions(gpsLogApplicationService);
    }

    private DeviceDto device(DeviceType deviceType) {
        return new DeviceDto(
                7L, 1L, "DEV-007", null, deviceType.name(), "ACTIVE", "online",
                null, null, null, null, null, null, null, null, null,
                null, null, null, null
        );
    }
}
