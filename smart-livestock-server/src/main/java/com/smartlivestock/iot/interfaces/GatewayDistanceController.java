package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.GatewayRegistryService;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.iot.domain.service.GatewayDistanceService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Per-gateway communication distance for one device (NIX-219 F2).
 * Response is grouped by gateway — never a single aggregated number.
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/devices/{deviceId}/gateway-distances")
@RequiredArgsConstructor
public class GatewayDistanceController {

    private final GatewayDistanceService gatewayDistanceService;
    private final IdentityQueryPort identityQueryPort;
    private final DeviceRepository deviceRepository;
    private final InstallationRepository installationRepository;
    private final RanchQueryPort ranchQueryPort;

    @GetMapping
    @PreAuthorize("hasAnyRole('OWNER', 'WORKER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<GatewayDistanceService.DeviceGatewayDistanceView>> deviceDistances(
            @PathVariable Long farmId,
            @PathVariable Long deviceId) {
        verifyFarmOwnership(farmId);
        verifyDeviceInFarm(deviceId, farmId);
        return ResponseEntity.ok(ApiResponse.ok(gatewayDistanceService.deviceDistances(deviceId)));
    }

    private void verifyFarmOwnership(Long farmId) {
        var farm = identityQueryPort.findFarmById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        Long currentTenant = TenantContext.getCurrentTenant();
        if (currentTenant != null && !farm.tenantId().equals(currentTenant)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
    }

    private void verifyDeviceInFarm(Long deviceId, Long farmId) {
        Device device = deviceRepository.findById(deviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备不存在: " + deviceId));
        Long deviceFarmId = installationRepository.findActiveByDeviceId(deviceId)
                .flatMap(inst -> ranchQueryPort.findLivestockById(inst.getLivestockId()))
                .map(LivestockInfo::farmId)
                .orElse(null);
        if (deviceFarmId == null || !deviceFarmId.equals(farmId)) {
            throw new ApiException(ErrorCode.FARM_SCOPE_CONFLICT, "设备不属于该牧场: " + device.getDeviceCode());
        }
    }
}
