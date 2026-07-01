package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.command.UpdateDeviceCommand;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DeviceApplicationService {

    private final DeviceRepository deviceRepository;

    @Transactional
    public DeviceDto registerDevice(RegisterDeviceCommand command) {
        if (deviceRepository.findByDeviceCode(command.deviceCode()).isPresent()) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                    "设备编号已存在: " + command.deviceCode());
        }
        Device device = new Device();
        device.setTenantId(command.tenantId());
        device.setDeviceCode(command.deviceCode());
        device.setDeviceType(command.deviceType());
        device.setDevEui(command.devEui());
        Device saved = deviceRepository.save(device);
        return DeviceDto.from(saved);
    }

    @Transactional
    public DeviceDto updateDevice(Long id, UpdateDeviceCommand command) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备不存在: " + id));
        if (!command.deviceCode().equals(device.getDeviceCode())) {
            deviceRepository.findByDeviceCode(command.deviceCode())
                    .ifPresent(existing -> {
                        if (!existing.getId().equals(id)) {
                            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                                    "设备编号已存在: " + command.deviceCode());
                        }
                    });
        }
        device.updateInfo(command.deviceCode(), command.devEui());
        Device saved = deviceRepository.save(device);
        return DeviceDto.from(saved);
    }

    @Transactional(readOnly = true)
    public DeviceDto getDevice(Long id) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备不存在: " + id));
        return DeviceDto.from(device);
    }

    @Transactional(readOnly = true)
    public List<DeviceDto> listByTenant(Long tenantId) {
        return deviceRepository.findByTenantId(tenantId).stream()
                .map(DeviceDto::from)
                .toList();
    }

    @Transactional
    public void activateDevice(Long id) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备不存在: " + id));
        device.activate();
        deviceRepository.save(device);
    }

    @Transactional
    public void markOffline(Long id) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备不存在: " + id));
        device.markOffline();
        deviceRepository.save(device);
    }

    @Transactional
    public void decommissionDevice(Long id) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备不存在: " + id));
        device.decommission();
        deviceRepository.save(device);
    }

    /**
     * Count ACTIVE devices for the current tenant.
     * Phase 1: tenant-level count (devices have no farm_id column).
     */
    @Transactional(readOnly = true)
    public long countActiveByTenant() {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) return 0L;
        return deviceRepository.countByTenantIdAndStatus(tenantId, DeviceStatus.ACTIVE.name());
    }
}
