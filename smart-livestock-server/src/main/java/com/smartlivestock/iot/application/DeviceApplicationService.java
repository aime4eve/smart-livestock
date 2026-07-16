package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.command.UpdateDeviceCommand;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformDeviceClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformLicenseClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceDetailResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DevicePageReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DevicePageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceRegistrationReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceRegistrationResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.LicenseStatusResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.LoginUser;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceApplicationService {

    private final DeviceRepository deviceRepository;
    private final AgenticPlatformDeviceClient platformDeviceClient;
    private final AgenticPlatformLicenseClient platformLicenseClient;

    /** Platform device type code mapping (local DeviceType → platform code). */
    private static final Map<DeviceType, String> PLATFORM_TYPE_CODES = Map.of(
            DeviceType.TRACKER, "CATTLE_TRACKER",
            DeviceType.CAPSULE, "RUMEN_CAPSULE",
            DeviceType.EAR_TAG, "EAR_TAG"
    );

    @Transactional
    public DeviceDto registerDevice(RegisterDeviceCommand command) {
        if (deviceRepository.findByDeviceCode(command.deviceCode()).isPresent()) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                    "error.deviceCodeDuplicate", new Object[]{command.deviceCode()});
        }
        Device device = new Device();
        device.setTenantId(command.tenantId());
        device.setDeviceCode(command.deviceCode());
        device.setSerialNo(command.serialNo());
        device.setDeviceType(command.deviceType());
        device.setDevEui(command.devEui());
        Device saved = deviceRepository.save(device);

        // 录入即注册：EUI 反查优先（设备已在 blade 注册则直接绑定），
        // 未命中走注册（方式一）。success → ACTIVE, failure → stay INVENTORY
        try {
            activateOnPlatform(saved);
            saved.activate();
            saved = deviceRepository.save(saved);
        } catch (Exception e) {
            log.warn("Platform registration failed for device {}: {}", saved.getId(), e.getMessage());
        }
        return DeviceDto.from(saved);
    }

    /**
     * Phase 3: Retry platform registration for a locally-created device.
     * Used when "录入即注册" platform step was skipped or failed.
     *
     * @param localDeviceId the local device ID (must already exist)
     */
    @Transactional
    public DeviceDto registerWithPlatform(Long localDeviceId) {
        Device device = deviceRepository.findById(localDeviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.deviceNotFound", new Object[]{localDeviceId}));

        if (device.getPlatformDeviceId() != null) {
            return DeviceDto.from(device);
        }

        activateOnPlatform(device);
        if (device.getStatus() == DeviceStatus.INVENTORY) {
            device.activate();
        }
        Device saved = deviceRepository.save(device);
        return DeviceDto.from(saved);
    }

    /**
     * Activate a device: obtain platformDeviceId (if missing) then transition INVENTORY → ACTIVE.
     * <ul>
     *   <li>Already ACTIVE → idempotent return (no-op).</li>
     *   <li>Not INVENTORY (e.g. DECOMMISSIONED) → STATE_CONFLICT.</li>
     *   <li>No platformDeviceId yet → first EUI reverse lookup (方式二), then registration (方式一).</li>
     * </ul>
     */
    @Transactional
    public DeviceDto activateDevice(Long id) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.deviceNotFound", new Object[]{id}));

        // Already activated — idempotent return
        if (device.getStatus() == DeviceStatus.ACTIVE) {
            return DeviceDto.from(device);
        }
        // Only INVENTORY devices can be activated (DECOMMISSIONED etc. rejected)
        if (device.getStatus() != DeviceStatus.INVENTORY) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.deviceActivateWrongStatus",
                    new Object[]{device.getStatus()});
        }

        // Obtain platformDeviceId first when not yet bound to blade platform
        if (device.getPlatformDeviceId() == null) {
            activateOnPlatform(device);
        }

        // Transition from INVENTORY to ACTIVE
        device.activate();
        Device saved = deviceRepository.save(device);
        return DeviceDto.from(saved);
    }

    /**
     * Acquire platformDeviceId during activation: first reverse lookup (方式二),
     * fall back to registration (方式一) when not found. On success device.platformDeviceId
     * is set; runtimeStatus is synced when available. Throws ApiException on failure.
     */
    private void activateOnPlatform(Device device) {
        String eui = device.getDevEui();

        // 方式二：EUI reverse lookup (only when devEui is present)
        if (eui != null && !eui.isBlank()) {
            DevicePageReq pageReq = new DevicePageReq();
            pageReq.setKeyword(eui);
            pageReq.setCurrent(1);
            pageReq.setSize(1);
            try {
                InternalResponse<DevicePageResp> pageResp = platformDeviceClient.pageDevices(pageReq);
                if (pageResp != null && pageResp.isOk() && pageResp.getData() != null
                        && pageResp.getData().getTotal() != null && pageResp.getData().getTotal() > 0) {
                    DeviceDetailResp record = pageResp.getData().getRecords().get(0);
                    device.bindPlatformDeviceId(Long.parseLong(record.getDeviceId()));
                    // Sync runtimeStatus from blade onlineStatus (1=online, otherwise offline)
                    device.setRuntimeStatus(
                            record.getOnlineStatus() != null && record.getOnlineStatus() == 1
                                    ? "online" : "offline");
                    return;
                }
            } catch (Exception e) {
                log.debug("EUI reverse lookup failed for device {}: {}", device.getId(), e.getMessage());
            }
        }

        // 方式一：SN → license → register
        doPlatformRegistration(device);
        // 方式一 success returns no onlineStatus; initialize runtimeStatus to offline
        if (device.getRuntimeStatus() == null) {
            device.setRuntimeStatus("offline");
        }
    }

    // --- Platform registration core logic (shared by registerDevice + registerWithPlatform) ---

    /**
     * Execute platform registration: license check → register → bind platformDeviceId.
     * License is queried by serialNo (not deviceCode). EUI is required to register.
     * Mutates the Device in-place. Caller is responsible for calling save().
     */
    private void doPlatformRegistration(Device device) {
        String sn = device.getSerialNo();
        String eui = device.getDevEui();
        String platformTypeCode = PLATFORM_TYPE_CODES.getOrDefault(device.getDeviceType(), "CATTLE_TRACKER");

        // Step 1: Check license on platform using serialNo (only when SN present)
        if (sn != null && !sn.isBlank()) {
            try {
                InternalResponse<LicenseStatusResp> licenseResp =
                        platformLicenseClient.getLicenseStatusBySn(sn);
                if (licenseResp != null && licenseResp.isOk() && licenseResp.getData() != null) {
                    LicenseStatusResp license = licenseResp.getData();
                    if (Boolean.FALSE.equals(license.getIsValid())) {
                        throw new ApiException(ErrorCode.AGENTIC_PLATFORM_LICENSE_INVALID,
                                "error.agenticPlatformLicenseInvalid", new Object[]{sn});
                    }
                    if (license.getDeviceTypeCode() != null && !license.getDeviceTypeCode().isBlank()) {
                        platformTypeCode = license.getDeviceTypeCode();
                    }
                    if (license.getDeviceEui() != null && !license.getDeviceEui().isBlank()) {
                        eui = license.getDeviceEui();
                    }
                }
            } catch (ApiException e) {
                throw e;
            } catch (Exception e) {
                log.debug("License query failed for SN={}: {}", sn, e.getMessage());
            }
        }

        // EUI must be present to register on platform
        if (eui == null || eui.isBlank()) {
            throw new ApiException(ErrorCode.AGENTIC_PLATFORM_REGISTRATION_FAILED,
                    "error.agenticPlatformRegistrationFailed",
                    new Object[]{"no devEui available for registration"});
        }

        // Step 2: Register on platform
        DeviceRegistrationReq req = new DeviceRegistrationReq();
        req.setDeviceIdentifier(eui);
        req.setDeviceTypeCode(platformTypeCode);
        String tenantIdStr = device.getTenantId() != null ? device.getTenantId().toString() : "000000";
        req.setUser(LoginUser.from("smart-livestock-server", tenantIdStr));

        InternalResponse<DeviceRegistrationResp> regResp;
        try {
            regResp = platformDeviceClient.registerDevice(req);
        } catch (Exception e) {
            throw new ApiException(ErrorCode.AGENTIC_PLATFORM_REGISTRATION_FAILED,
                    "error.agenticPlatformRegistrationFailed", new Object[]{e.getMessage()});
        }

        if (regResp == null || !regResp.isOk() || regResp.getData() == null
                || regResp.getData().getDeviceId() == null) {
            throw new ApiException(ErrorCode.AGENTIC_PLATFORM_REGISTRATION_FAILED,
                    "error.agenticPlatformRegistrationFailed", new Object[]{"no deviceId returned"});
        }

        // Step 3: Bind platformDeviceId locally
        Long platformDeviceId = Long.parseLong(regResp.getData().getDeviceId());
        device.bindPlatformDeviceId(platformDeviceId);
    }

    @Transactional
    public DeviceDto updateDevice(Long id, UpdateDeviceCommand command) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.deviceNotFound", new Object[]{id}));
        if (!command.deviceCode().equals(device.getDeviceCode())) {
            deviceRepository.findByDeviceCode(command.deviceCode())
                    .ifPresent(existing -> {
                        if (!existing.getId().equals(id)) {
                            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                                    "error.deviceCodeDuplicate", new Object[]{command.deviceCode()});
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
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.deviceNotFound", new Object[]{id}));
        return DeviceDto.from(device);
    }

    @Transactional(readOnly = true)
    public List<DeviceDto> listByTenant(Long tenantId) {
        return deviceRepository.findByTenantId(tenantId).stream()
                .map(DeviceDto::from)
                .toList();
    }

    /**
     * Paginated device query with optional keyword search.
     */
    @Transactional(readOnly = true)
    public DevicePage listByTenant(Long tenantId, String keyword, int page, int pageSize) {
        String kw = (keyword != null && !keyword.isBlank()) ? keyword.trim() : null;
        int safePage = Math.max(1, page);
        int offset = (safePage - 1) * pageSize;
        java.util.List<DeviceDto> items;
        long total;
        if (kw != null) {
            items = deviceRepository.findByTenantIdAndKeyword(tenantId, kw, offset, pageSize)
                    .stream().map(DeviceDto::from).toList();
            total = deviceRepository.countByTenantIdAndKeyword(tenantId, kw);
        } else {
            items = deviceRepository.findByTenantIdPaged(tenantId, offset, pageSize)
                    .stream().map(DeviceDto::from).toList();
            total = deviceRepository.countByTenantIdPaged(tenantId);
        }
        return new DevicePage(items, page, pageSize, total);
    }

    public record DevicePage(java.util.List<DeviceDto> items, int page, int pageSize, long total) {}

    @Transactional
    public void decommissionDevice(Long id) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.deviceNotFound", new Object[]{id}));
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
