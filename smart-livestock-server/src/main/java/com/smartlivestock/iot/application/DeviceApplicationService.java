package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.command.UpdateDeviceCommand;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.application.dto.DeviceTransferLookupDto;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
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
import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
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
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceApplicationService {

    private final DeviceRepository deviceRepository;
    private final AgenticPlatformDeviceClient platformDeviceClient;
    private final AgenticPlatformLicenseClient platformLicenseClient;
    private final InstallationApplicationService installationApplicationService;
    private final InstallationRepository installationRepository;
    private final com.smartlivestock.identity.application.TenantZoneResolver tenantZoneResolver;
    private final com.smartlivestock.identity.domain.repository.TenantRepository tenantRepository;
    private final AuditLogRepository auditLogRepository;

    /** Platform device type code mapping (local DeviceType → platform code). */
    private static final Map<DeviceType, String> PLATFORM_TYPE_CODES = Map.of(
            DeviceType.TRACKER, "CATTLE_TRACKER",
            DeviceType.CAPSULE, "RUMEN_CAPSULE",
            DeviceType.EAR_TAG, "EAR_TAG"
    );

    /** Device EUIs are case-insensitive and always stored lowercase. */
    private static String normalizeEui(String devEui) {
        return devEui == null ? null : devEui.toLowerCase(Locale.ROOT);
    }

    // ── Platform-admin device handover (ruling 2026-10-19) ─────────────

    /**
     * Where does an EUI live today? Feeds the admin console handover dialog:
     * current owner tenant + whether an active installation blocks the move.
     */
    @Transactional(readOnly = true)
    public DeviceTransferLookupDto lookupForTransfer(String devEui) {
        String eui = normalizeEui(devEui);
        if (eui == null || eui.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.deviceTransferEuiRequired");
        }
        return deviceRepository.findAllByDevEuiIncludeDeleted(eui).stream()
                .filter(d -> d.getDeletedAt() == null)
                .findFirst()
                .map(device -> {
                    String tenantName = tenantRepository.findById(device.getTenantId())
                            .map(t -> t.getName()).orElse(null);
                    boolean activeInstallation = installationRepository
                            .findActiveByDeviceId(device.getId()).isPresent();
                    return new DeviceTransferLookupDto(
                            true, device.getId(), device.getDeviceCode(),
                            device.getDeviceType() == null ? null : device.getDeviceType().name(),
                            device.getStatus() == null ? null : device.getStatus().name(),
                            device.getTenantId(), tenantName, activeInstallation);
                })
                .orElse(DeviceTransferLookupDto.notFound());
    }

    /**
     * Move a device's tenant ownership by EUI. The provisioning wizard's
     * cross-tenant guard tells customers to "contact the platform admin for
     * a handover" — this is that handover, with the guardrails the manual
     * SQL path lacked: blocked while an active installation exists in the
     * source tenant (unbind first), target tenant must exist, and every move
     * is audited. Telemetry history stays with the old tenant by design.
     */
    @Transactional
    public DeviceDto transferToTenant(String devEui, Long targetTenantId, Long operatorId) {
        String eui = normalizeEui(devEui);
        if (eui == null || eui.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.deviceTransferEuiRequired");
        }
        if (targetTenantId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.deviceTransferTenantRequired");
        }
        Device device = deviceRepository.findAllByDevEuiIncludeDeleted(eui).stream()
                .filter(d -> d.getDeletedAt() == null)
                .findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.deviceTransferNotFound", new Object[]{eui}));
        if (targetTenantId.equals(device.getTenantId())) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "error.deviceTransferSameTenant");
        }
        tenantRepository.findById(targetTenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.deviceTransferTenantNotFound", new Object[]{targetTenantId}));
        installationRepository.findActiveByDeviceId(device.getId())
                .ifPresent(installation -> {
                    throw new ApiException(ErrorCode.STATE_CONFLICT,
                            "error.deviceTransferActiveInstallation", new Object[]{eui});
                });

        Long fromTenantId = device.getTenantId();
        device.setTenantId(targetTenantId);
        Device saved = deviceRepository.save(device);
        auditDeviceTransfer(operatorId, eui, saved.getId(), fromTenantId, targetTenantId);
        log.info("Device {} ({}) handed over: tenant {} -> {} by operator {}",
                eui, saved.getId(), fromTenantId, targetTenantId, operatorId);
        return DeviceDto.from(saved);
    }

    private void auditDeviceTransfer(Long operatorId, String eui, Long deviceId,
                                     Long fromTenantId, Long toTenantId) {
        try {
            Map<String, Object> details = new LinkedHashMap<>();
            details.put("devEui", eui);
            details.put("deviceId", deviceId);
            details.put("fromTenantId", fromTenantId);
            details.put("toTenantId", toTenantId);
            auditLogRepository.save(new AuditLog(
                    UUID.randomUUID().toString(),
                    "DEVICE_TENANT_TRANSFERRED",
                    toTenantId,
                    operatorId,
                    "DEVICE_TENANT_TRANSFERRED",
                    details,
                    Instant.now(),
                    null,
                    "PLATFORM_ADMIN"));
        } catch (Exception e) {
            log.error("Failed to audit device transfer for {}", eui, e);
        }
    }

    @Transactional
    public DeviceDto registerDevice(RegisterDeviceCommand command) {
        String devEui = normalizeEui(command.devEui());
        // EUI branch: same devEui = same physical device → revive soft-deleted record;
        // an active record with the same EUI is a business error (not a new device).
        if (devEui != null && !devEui.isBlank()) {
            // Global ownership guard (ruling 2026-10-12): an EUI is globally unique
            // and maps 1:1 to exactly one tenant. If any row (active or soft-deleted)
            // already belongs to another tenant, reject — cross-tenant handover is a
            // manual operation, never a side effect of registration.
            boolean ownedByOtherTenant = deviceRepository.findAllByDevEuiIncludeDeleted(devEui).stream()
                    .anyMatch(device -> !command.tenantId().equals(device.getTenantId()));
            if (ownedByOtherTenant) {
                throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                        "error.deviceEuiOwnedByOtherTenant", new Object[]{devEui});
            }
            List<Device> euiMatches = deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(
                    devEui, command.tenantId());
            if (!euiMatches.isEmpty()) {
                Device match = euiMatches.get(0);
                if (match.getDeletedAt() == null) {
                    throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                            "error.deviceEuiDuplicate", new Object[]{devEui});
                }
                // Revive: check deviceCode against the active set first (avoids partial-index 500)
                deviceRepository.findByDeviceCode(command.deviceCode())
                        .ifPresent(active -> {
                            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                                    "error.deviceCodeDuplicate", new Object[]{command.deviceCode()});
                        });
                match.restore();
                match.setDeviceCode(command.deviceCode());
                // serialNo: only overwrite when a non-blank value is passed — the controller
                // allows devEui-only registration, and null would erase the preserved SN
                // (same protection as the deviceCode guard in findOrCreateByEui's revive branch)
                if (command.serialNo() != null && !command.serialNo().isBlank()) {
                    match.setSerialNo(command.serialNo());
                }
                match.setDeviceType(command.deviceType());
                // native UPDATE must run before save() so merge's internal SELECT can load the row;
                // pass the FINAL deviceCode (match already holds command's value) — clearing
                // deleted_at with the row's old code could violate uq_devices_code_active
                deviceRepository.restoreById(match.getId(), match.getDeviceCode());
                Device restored = deviceRepository.save(match);

                // Same "register on platform" flow as a new device
                try {
                    activateOnPlatform(restored);
                    restored.activate();
                    restored = deviceRepository.save(restored);
                } catch (Exception e) {
                    log.warn("Platform registration failed for device {}: {}", restored.getId(), e.getMessage());
                }
                return DeviceDto.from(restored);
            }
        }

        if (deviceRepository.findByDeviceCode(command.deviceCode()).isPresent()) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                    "error.deviceCodeDuplicate", new Object[]{command.deviceCode()});
        }
        Device device = new Device();
        device.setTenantId(command.tenantId());
        device.setDeviceCode(command.deviceCode());
        device.setSerialNo(command.serialNo());
        device.setDeviceType(command.deviceType());
        device.setDevEui(devEui);
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
    * Find or create a device by devEui within a tenant scope.
     * Used by GPS quality batch import to resolve or auto-register devices.
     *
     * @param eui        device devEui (required, >= 4 chars)
     * @param deviceCode optional human-friendly code; defaults to "GPS-" + eui
     * @param tenantId   tenant scope
     * @return DeviceDto with final status
     */
    @Transactional
    public DeviceDto findOrCreateByEui(String eui, String deviceCode, Long tenantId) {
        // 1. Validate EUI
        if (eui == null || eui.isBlank() || eui.length() < 4) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "iot.invalidEuiFormat", new Object[]{eui});
        }
        eui = normalizeEui(eui);
        if (tenantId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "tenantId is required for device creation");
        }

        // 2. Lookup by EUI within tenant scope, including soft-deleted rows (revive detection)
        // Global ownership guard first (ruling 2026-10-12): 1:1 EUI↔tenant mapping,
        // cross-tenant claims are rejected instead of silently creating a second row.
        boolean ownedByOtherTenant = deviceRepository.findAllByDevEuiIncludeDeleted(eui).stream()
                .anyMatch(device -> !tenantId.equals(device.getTenantId()));
        if (ownedByOtherTenant) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                    "error.deviceEuiOwnedByOtherTenant", new Object[]{eui});
        }
        List<Device> existing = deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(eui, tenantId);

        if (!existing.isEmpty()) {
            Device device = existing.get(0);

            // Soft-deleted record → revive (same devEui = same physical device)
            if (device.getDeletedAt() != null) {
                // deviceCode: only update when a different non-blank value is passed;
                // check against the active set first (avoids partial-index 500)
                if (deviceCode != null && !deviceCode.isBlank() && !deviceCode.equals(device.getDeviceCode())) {
                    deviceRepository.findByDeviceCode(deviceCode)
                            .ifPresent(active -> {
                                throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                                        "error.deviceCodeDuplicate", new Object[]{deviceCode});
                            });
                    device.setDeviceCode(deviceCode);
                }
                device.restore();
                // native UPDATE must run before save() so merge's internal SELECT can load the row;
                // pass the FINAL deviceCode (device already holds the post-guard value)
                deviceRepository.restoreById(device.getId(), device.getDeviceCode());
                device = deviceRepository.save(device);
            }

            // Already has platformDeviceId → skip registration entirely
            if (device.getPlatformDeviceId() != null) {
                log.info("Device EUI {} already registered (platformDeviceId={}), skip registration",
                        eui, device.getPlatformDeviceId());
                return DeviceDto.from(device);
            }

            // Binding gate: try platform binding for ANY status when not yet bound (v3.2).
            // Two independent conditions: activateOnPlatform only binds (status-machine
            // independent); activate() only runs for INVENTORY. The binding result is
            // persisted for any status so ACTIVE/DECOMMISSIONED devices don't stay unbound.
            if (device.getPlatformDeviceId() == null) {
                try {
                    activateOnPlatform(device);
                    if (device.getStatus() == DeviceStatus.INVENTORY) {
                        device.activate();
                    }
                    device = deviceRepository.save(device);
                } catch (Exception ex) {
                    log.warn("Platform registration retry failed for device {} EUI {}: {}",
                            device.getId(), eui, ex.getMessage());
                }
            }
            return DeviceDto.from(device);
        }

        // 3. Create new device
        String resolvedCode = (deviceCode != null && !deviceCode.isBlank())
                ? deviceCode : "GPS-" + eui;

        Device device = new Device();
        device.setDevEui(eui);
        device.setDeviceCode(resolvedCode);
        device.setSerialNo(eui);
        device.setDeviceType(DeviceType.TRACKER);
        device.setTenantId(tenantId);
        Device saved = deviceRepository.save(device);

        // 4. Try platform registration (best-effort)
        try {
            activateOnPlatform(saved);
            saved.activate();
            saved = deviceRepository.save(saved);
        } catch (Exception ex) {
            log.warn("Platform registration failed for new device EUI {}: {}", eui, ex.getMessage());
        }
        return DeviceDto.from(saved);
    }

    /**
     * Phase 3: Retry platform registration for a locally-created device.
     * Used when "录入即注册" platform step was skipped or failed.
     *
     * @param localDeviceId the local device ID (must already exist)
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
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
        // Blade X-TimeZone convention (ruling 2026-10-12): register under the
        // device's tenant timezone. Shared threads — always clear.
        com.smartlivestock.iot.infrastructure.client.agenticplatform.AgenticPlatformTimeZoneContext
                .set(tenantZoneResolver.zoneForTenantStrict(device.getTenantId()).getId());
        try {
            activateOnPlatformInternal(device);
        } finally {
            com.smartlivestock.iot.infrastructure.client.agenticplatform.AgenticPlatformTimeZoneContext.clear();
        }
    }

    private void activateOnPlatformInternal(Device device) {
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
        device.updateInfo(command.deviceCode(), normalizeEui(command.devEui()));
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
     * Paginated device query with optional keyword search. When unboundOnly is
     * set, devices holding an active installation are excluded server-side so
     * bind pickers can page through large inventories without client-side
     * filtering.
     */
    @Transactional(readOnly = true)
    public DevicePage listByTenant(Long tenantId, String keyword, boolean unboundOnly, int page, int pageSize) {
        String kw = (keyword != null && !keyword.isBlank()) ? keyword.trim() : null;
        int safePage = Math.max(1, page);
        int offset = (safePage - 1) * pageSize;
        java.util.List<DeviceDto> items;
        long total;
        if (unboundOnly) {
            items = (kw != null
                    ? deviceRepository.findByTenantIdUnboundAndKeyword(tenantId, kw, offset, pageSize)
                    : deviceRepository.findByTenantIdUnboundPaged(tenantId, offset, pageSize))
                    .stream().map(DeviceDto::from).toList();
            total = kw != null
                    ? deviceRepository.countByTenantIdUnboundAndKeyword(tenantId, kw)
                    : deviceRepository.countByTenantIdUnbound(tenantId);
        } else if (kw != null) {
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
     * Soft-delete a device in a single transaction:
     * <ol>
     *   <li>Validate existence + tenant scope (cross-tenant lookup reports NOT_FOUND,
     *       existence is not exposed);</li>
     *   <li>Unbind the active installation if present (primary mechanism to stop datagen);</li>
     *   <li>Mark deleted_at — the global @SQLRestriction filter stops blade sync for
     *       platform-bound devices. Lifecycle status is NOT changed;
     *       deviceCode/serialNo/devEui/platformDeviceId are preserved for audit + revive.</li>
     * </ol>
     */
    @Transactional
    public void deleteDevice(Long id, Long operatorId) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.deviceNotFound", new Object[]{id}));
        if (!device.getTenantId().equals(TenantContext.getCurrentTenant())) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                    "error.deviceNotFound", new Object[]{id});
        }
        if (installationApplicationService.getActiveInstallation(id).isPresent()) {
            installationApplicationService.remove(id, operatorId);
        }
        device.setDeletedAt(Instant.now());
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
