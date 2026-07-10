package com.ai.openapi.device.controller;

import com.ai.openapi.common.response.OpenApiResponse;
import com.ai.openapi.common.validation.OpenApiPatterns;
import com.ai.openapi.device.dto.external.*;
import com.ai.openapi.device.service.DeviceBffService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Validated
@RestController
@RequestMapping("/v1/devices")
public class DeviceController {

    private final DeviceBffService deviceBffService;

    public DeviceController(DeviceBffService deviceBffService) {
        this.deviceBffService = deviceBffService;
    }

    @GetMapping
    public ResponseEntity<OpenApiResponse<DeviceVO>> listDevices(
            @RequestParam(required = false) @Size(max = 100, message = "keyword 长度不能超过 100") String keyword,
            @RequestParam(value = "spaceId", required = false)
            @Pattern(regexp = OpenApiPatterns.OPTIONAL_NUMERIC_ID, message = "spaceId 须为不超过21位的数字 ID") String spaceId,
            @RequestParam(defaultValue = "1") @Min(1) @Max(1_000_000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(200) int pageSize) {
        OpenApiResponse<DeviceVO> response = deviceBffService.listDevices(keyword, spaceId, page, pageSize);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{device_id}")
    public ResponseEntity<DeviceDetailVO> getDevice(
            @PathVariable("device_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "device_id 须为 1～21 位数字 ID") String deviceId) {
        DeviceDetailVO detail = deviceBffService.getDeviceDetail(deviceId);
        return ResponseEntity.ok(detail);
    }

    @PostMapping
    public ResponseEntity<RegisterDeviceResponse> registerDevice(@Valid @RequestBody RegisterDeviceRequest request) {
        RegisterDeviceResponse response = deviceBffService.registerDevice(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/{device_id}")
    public ResponseEntity<DeviceVO> updateDevice(
            @PathVariable("device_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "device_id 须为 1～21 位数字 ID") String deviceId,
                                                  @Valid @RequestBody UpdateDeviceRequest request) {
        DeviceVO device = deviceBffService.updateDevice(deviceId, request);
        return ResponseEntity.ok(device);
    }

    @DeleteMapping("/{device_id}")
    public ResponseEntity<Map<String, Object>> deleteDevice(
            @PathVariable("device_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "device_id 须为 1～21 位数字 ID") String deviceId) {
        boolean deleted = deviceBffService.deleteDevice(deviceId);
        return ResponseEntity.ok(Map.of("device_id", deviceId, "deleted", deleted));
    }

    @GetMapping("/{device_id}/telemetry")
    public ResponseEntity<DeviceTelemetryVO> getDeviceTelemetry(
            @PathVariable("device_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "device_id 须为 1～21 位数字 ID") String deviceId) {
        DeviceTelemetryVO telemetry = deviceBffService.getDeviceTelemetry(deviceId);
        return ResponseEntity.ok(telemetry);
    }

    @GetMapping("/{device_id}/history-data")
    public ResponseEntity<OpenApiResponse<Map<String, Object>>> queryDeviceHistoryData(
            @PathVariable("device_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "device_id 须为 1～21 位数字 ID") String deviceId,
            @RequestParam String start_time,
            @RequestParam String end_time,
            @RequestParam(defaultValue = "1") @Min(1) @Max(1_000_000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(200) int pageSize,
            @RequestHeader(value = "X-Locale", required = false, defaultValue = "zh") String locale) {
        OpenApiResponse<Map<String, Object>> response = deviceBffService.queryDeviceHistoryData(
                deviceId, start_time, end_time, page, pageSize, locale);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/sub-devices/{sub_device_id}/history-data")
    public ResponseEntity<OpenApiResponse<Map<String, Object>>> querySubDeviceHistoryData(
            @PathVariable("sub_device_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "sub_device_id 须为 1～21 位数字 ID") String subDeviceId,
            @RequestParam String start_time,
            @RequestParam String end_time,
            @RequestParam(defaultValue = "1") @Min(1) @Max(1_000_000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(200) int pageSize,
            @RequestHeader(value = "X-Locale", required = false, defaultValue = "zh") String locale) {
        OpenApiResponse<Map<String, Object>> response = deviceBffService.querySubDeviceHistoryData(
                subDeviceId, start_time, end_time, page, pageSize, locale);
        return ResponseEntity.ok(response);
    }
}
