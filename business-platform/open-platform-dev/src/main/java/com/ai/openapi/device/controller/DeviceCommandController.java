package com.ai.openapi.device.controller;

import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.validation.OpenApiPatterns;
import com.ai.openapi.device.dto.external.DeviceCommandStatusVO;
import com.ai.openapi.device.dto.external.SendDeviceCommandRequest;
import com.ai.openapi.device.dto.external.SendDeviceCommandResponse;
import com.ai.openapi.device.service.DeviceBffService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Tag(name = "设备控制", description = "设备命令下发、设置等（部分已对接设备中台）")
@Validated
@RestController
public class DeviceCommandController {

    private final DeviceBffService deviceBffService;

    public DeviceCommandController(DeviceBffService deviceBffService) {
        this.deviceBffService = deviceBffService;
    }

    @Operation(summary = "下发命令", description = "业务指令下发，转发设备服务 businessCmdDown（支持子设备）")
    @PostMapping("/v1/devices/{device_id}/commands")
    public ResponseEntity<SendDeviceCommandResponse> sendCommand(
            @PathVariable("device_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "device_id 须为 1～21 位数字 ID") String deviceId,
            @Valid @RequestBody SendDeviceCommandRequest body) {
        SendDeviceCommandResponse result = deviceBffService.sendDeviceCommand(deviceId, body);
        return ResponseEntity.ok(result);
    }

    @Operation(summary = "更新设备设置", description = "更新设备的配置设置（待实现）")
    @PutMapping("/v1/devices/{device_id}/settings")
    public ResponseEntity<Map<String, Object>> updateSettings(
            @PathVariable("device_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "device_id 须为 1～21 位数字 ID") String deviceId,
            @RequestBody Map<String, Object> body) {
        throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(),
                ErrorCode.NOT_FOUND.getCode(), "设备设置接口暂未开放");
    }

    @Operation(summary = "取消命令", description = "取消已下发的命令（待实现）")
    @DeleteMapping("/v1/devices/{device_id}/commands/{command_id}")
    public ResponseEntity<Map<String, Object>> cancelCommand(
            @PathVariable("device_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "device_id 须为 1～21 位数字 ID") String deviceId,
            @PathVariable("command_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "command_id 须为 1～21 位数字 ID") String commandId) {
        throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(),
                ErrorCode.NOT_FOUND.getCode(), "命令取消接口暂未开放");
    }

    @Operation(summary = "查询命令状态", description = "按控制记录 ID 查询执行状态，转发设备服务 queryControlRecordByIds")
    @GetMapping("/v1/commands/{command_id}/status")
    public ResponseEntity<DeviceCommandStatusVO> getCommandStatus(
            @PathVariable("command_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "command_id 须为 1～21 位数字 ID") String commandId) {
        DeviceCommandStatusVO vo = deviceBffService.getCommandStatus(commandId);
        return ResponseEntity.ok(vo);
    }
}
