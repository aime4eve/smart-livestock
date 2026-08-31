package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.HealthDtos.DeviceHealthSeries;
import com.smartlivestock.health.application.service.DeviceHealthSeriesApplicationService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/health/devices")
@RequiredArgsConstructor
public class DeviceHealthSeriesController {

    private final DeviceHealthSeriesApplicationService service;

    @GetMapping("/{deviceId}")
    public ResponseEntity<ApiResponse<DeviceHealthSeries>> getSeries(
            @PathVariable Long farmId,
            @PathVariable Long deviceId) {
        return ResponseEntity.ok(ApiResponse.ok(service.getSeries(deviceId)));
    }
}
