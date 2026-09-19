package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.LivestockPresenceService;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.LivestockRoamDaily;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * F6 roaming-radius history for one device (NIX-219 P3): daily max/mean
 * distance to the receiving gateway, for the health-profile dimension.
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/devices/{deviceId}/roam-radius")
@RequiredArgsConstructor
public class LivestockRoamController {

    private final LivestockPresenceService presenceService;
    private final IdentityQueryPort identityQueryPort;
    private final DeviceRepository deviceRepository;
    private final InstallationRepository installationRepository;
    private final RanchQueryPort ranchQueryPort;

    @GetMapping
    @PreAuthorize("hasAnyRole('OWNER', 'WORKER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> roamHistory(
            @PathVariable Long farmId,
            @PathVariable Long deviceId,
            @RequestParam(defaultValue = "30") int days) {
        verifyFarmOwnership(farmId);
        verifyDeviceInFarm(deviceId, farmId);
        int window = Math.max(1, Math.min(days, 90));
        LocalDate to = LocalDate.now();
        LocalDate from = to.minusDays(window - 1);
        List<LivestockRoamDaily> items = presenceService.roamHistory(deviceId, from, to);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "deviceId", deviceId,
                "from", from,
                "to", to,
                "items", items)));
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
