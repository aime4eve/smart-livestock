package com.smartlivestock.iot.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import com.smartlivestock.iot.infrastructure.client.devicehub.DeviceHubClient;
import com.smartlivestock.iot.infrastructure.client.devicehub.dto.ReconcileReport;
import com.smartlivestock.iot.infrastructure.client.devicehub.dto.RegisterDeviceRequest;
import com.smartlivestock.iot.infrastructure.client.devicehub.dto.RegisterDeviceResult;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import feign.FeignException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * DeviceHub-backed provisioning orchestration (gray rollout path).
 * <p>
 * When smartlivestock.devicehub.enabled=true, the TB-side registration
 * (resolve/create ThingsBoard device) is delegated to the shared HKT-DeviceHub
 * service (project LIVESTOCK). After a successful hub registration the
 * devEui↔tbDeviceId mapping is written back to the local tb_device_bindings
 * table (and a local device is created when missing and the caller supplied a
 * deviceType), so the DeviceHub telemetry consumer can resolve frames and the
 * legacy pull channel keeps working during the dual-run window.
 */
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "smartlivestock.devicehub.enabled", havingValue = "true")
@Slf4j
public class DeviceHubProvisioningService {

    private static final String PROJECT = "LIVESTOCK";
    private static final String HUB_STATUS_ACTIVE = "ACTIVE";
    private static final Pattern EUI_PATTERN = Pattern.compile("^[0-9a-f]{16}$");

    private final DeviceHubClient deviceHubClient;
    private final DeviceRepository deviceRepository;
    private final TbDeviceBindingRepository bindingRepository;
    private final InstallationRepository installationRepository;
    private final AuditLogRepository auditLogRepository;
    private final RanchQueryPort ranchQueryPort;
    private final ObjectMapper objectMapper;

    public record ProvisionCommand(
            String eui, String deviceCode, DeviceType deviceType, Long livestockId) {}

    public record ProvisionResult(
            String eui, String tbDeviceId, String hubStatus, String hubResult,
            Long localDeviceId, String deviceCode, Long bindingId, String bindingStatus,
            boolean bindingWritten) {}

    public record ImportItem(String eui, String deviceCode) {}

    public record ImportReport(List<RegisterDeviceResult> results, long bindingsWritten) {}

    @Transactional
    public ProvisionResult provision(ProvisionCommand command, Long tenantId, Long farmId, Long operatorId) {
        String eui = requireEui(command.eui());
        validateLivestock(farmId, command.livestockId());

        Map<String, Object> capabilities = command.deviceType() == null ? null
                : Map.of("deviceType", command.deviceType().name());
        RegisterDeviceResult result = registerViaHub(eui, command.deviceCode(), capabilities);

        List<Device> matches = deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(eui, tenantId);
        Device device = matches.stream().filter(item -> item.getDeletedAt() == null).findFirst().orElse(null);
        boolean softDeleted = matches.stream().anyMatch(item -> item.getDeletedAt() != null);
        if (device == null && softDeleted) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.tb.localDeviceSoftDeleted", new Object[]{eui});
        }
        if (device == null && command.deviceType() == null) {
            // Without a deviceType the local device cannot be created; the hub
            // registration itself succeeded, so report it without write-back.
            log.warn("[DeviceHub] {} registered (tbDeviceId={}) but no local device and no deviceType "
                    + "provided; skipping local binding write-back", eui, result.tbDeviceId());
            return new ProvisionResult(eui, result.tbDeviceId(), result.status(), result.result(),
                    null, null, null, null, false);
        }

        boolean installationCreated = false;
        if (device == null) {
            String deviceCode = command.deviceCode();
            if (deviceCode == null || deviceCode.isBlank()) {
                deviceCode = "TB-" + eui;
            }
            final String resolvedDeviceCode = deviceCode;
            deviceRepository.findByDeviceCode(resolvedDeviceCode).ifPresent(existing -> {
                throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                        "error.deviceCodeDuplicate", new Object[]{resolvedDeviceCode});
            });
            device = new Device();
            device.setTenantId(tenantId);
            device.setDeviceCode(resolvedDeviceCode);
            device.setSerialNo(eui);
            device.setDevEui(eui);
            device.setDeviceType(command.deviceType());
            device = deviceRepository.save(device);
        }
        if (device.getStatus() == DeviceStatus.INVENTORY) {
            device.activate();
            device = deviceRepository.save(device);
        } else if (device.getStatus() != DeviceStatus.ACTIVE) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "error.deviceNotActiveForInstall", new Object[]{device.getId()});
        }

        TbDeviceBinding binding = writeBackBinding(device, eui, result.tbDeviceId(), tenantId);

        if (command.livestockId() != null) {
            Installation existing = installationRepository.findActiveByDeviceId(device.getId()).orElse(null);
            if (existing == null) {
                installationRepository.save(new Installation(device.getId(), command.livestockId(), operatorId));
                installationCreated = true;
            } else if (!existing.getLivestockId().equals(command.livestockId())) {
                throw new ApiException(ErrorCode.STATE_CONFLICT,
                        "error.deviceAlreadyInstalled", new Object[]{device.getId()});
            }
        }

        recordAudit("DEVICEHUB_DEVICE_PROVISIONED", tenantId, operatorId, Map.of(
                "eui", eui,
                "tbDeviceId", result.tbDeviceId(),
                "hubResult", String.valueOf(result.result()),
                "localDeviceId", device.getId(),
                "bindingId", binding.getId() == null ? "" : binding.getId(),
                "installationCreated", installationCreated,
                "livestockId", command.livestockId() == null ? "" : command.livestockId()));
        return new ProvisionResult(eui, result.tbDeviceId(), result.status(), result.result(),
                device.getId(), device.getDeviceCode(), binding.getId(), binding.getStatus().name(), true);
    }

    @Transactional
    public ImportReport importDevices(List<ImportItem> items, Long tenantId, Long operatorId) {
        List<RegisterDeviceRequest> requests = new ArrayList<>();
        for (ImportItem item : items) {
            requests.add(new RegisterDeviceRequest(
                    requireEui(item.eui()), PROJECT, item.deviceCode(), null));
        }
        List<RegisterDeviceResult> results;
        try {
            results = deviceHubClient.importBatch(requests);
        } catch (FeignException e) {
            throw hubUnavailable(e);
        }
        long bindingsWritten = 0;
        for (RegisterDeviceResult result : results) {
            if (!HUB_STATUS_ACTIVE.equals(result.status()) || result.tbDeviceId() == null) {
                continue;
            }
            String eui = TbDeviceProvisioningService.normalizeEui(result.devEui());
            Device device = deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(eui, tenantId)
                    .stream().filter(item -> item.getDeletedAt() == null).findFirst().orElse(null);
            if (device == null) {
                log.warn("[DeviceHub] import {} registered (tbDeviceId={}) but no local device; "
                        + "binding write-back skipped", eui, result.tbDeviceId());
                continue;
            }
            try {
                writeBackBinding(device, eui, result.tbDeviceId(), tenantId);
                bindingsWritten++;
            } catch (ApiException e) {
                log.warn("[DeviceHub] import {} binding write-back failed: {}", eui, e.getMessage());
            }
        }
        recordAudit("DEVICEHUB_DEVICES_IMPORTED", tenantId, operatorId, Map.of(
                "count", items.size(),
                "bindingsWritten", bindingsWritten));
        return new ImportReport(results, bindingsWritten);
    }

    @Transactional(readOnly = true)
    public ReconcileReport reconcile() {
        try {
            return deviceHubClient.reconcile(PROJECT);
        } catch (FeignException e) {
            throw hubUnavailable(e);
        }
    }

    private RegisterDeviceResult registerViaHub(
            String eui, String deviceCode, Map<String, Object> capabilities) {
        try {
            RegisterDeviceResult result = deviceHubClient.register(
                    new RegisterDeviceRequest(eui, PROJECT, deviceCode, capabilities));
            if (result == null || result.tbDeviceId() == null || !HUB_STATUS_ACTIVE.equals(result.status())) {
                throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.devicehub.registerFailed",
                        new Object[]{eui, result == null ? "EMPTY_RESPONSE" : result.result()});
            }
            return result;
        } catch (FeignException e) {
            // DeviceHub answers 422 with the RegisterResult body on business failures.
            RegisterDeviceResult failure = decodeFailureBody(e);
            String detail = failure != null ? failure.result() : e.getMessage();
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.devicehub.registerFailed",
                    new Object[]{eui, detail});
        }
    }

    private RegisterDeviceResult decodeFailureBody(FeignException e) {
        try {
            String body = e.contentUTF8();
            return body == null || body.isBlank() ? null
                    : objectMapper.readValue(body, RegisterDeviceResult.class);
        } catch (Exception ignored) {
            return null;
        }
    }

    private TbDeviceBinding writeBackBinding(Device device, String eui, String tbDeviceId, Long tenantId) {
        TbDeviceBinding binding = bindingRepository
                .findByProviderAndExternalDeviceId(TbDeviceBinding.PROVIDER_THINGSBOARD, tbDeviceId)
                .orElse(null);
        if (binding != null && !binding.getDeviceId().equals(device.getId())) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.tb.bindingIdentityConflict",
                    new Object[]{tbDeviceId});
        }
        if (binding == null) {
            binding = bindingRepository.findByDeviceIdAndProvider(
                            device.getId(), TbDeviceBinding.PROVIDER_THINGSBOARD)
                    .orElseGet(TbDeviceBinding::new);
        }
        if (binding.getId() != null && !Objects.equals(binding.getExternalDeviceId(), tbDeviceId)) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.tb.bindingIdentityConflict",
                    new Object[]{tbDeviceId});
        }
        binding.setTenantId(tenantId);
        binding.setDeviceId(device.getId());
        binding.setProvider(TbDeviceBinding.PROVIDER_THINGSBOARD);
        binding.setDeviceEui(eui);
        binding.setExternalDeviceId(tbDeviceId);
        // TB device names carry the devEui in this deployment topology.
        binding.setExternalDeviceName(eui);
        binding.setStatus(TbDeviceBinding.Status.RESOLVED);
        binding.setLastVerifiedAt(Instant.now());
        return bindingRepository.save(binding);
    }

    private void validateLivestock(Long farmId, Long livestockId) {
        if (livestockId == null) return;
        boolean belongsToFarm = ranchQueryPort.findAllByFarmId(farmId).stream()
                .anyMatch(livestock -> livestock.id().equals(livestockId));
        if (!belongsToFarm) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "iot.tb.livestockNotInFarm",
                    new Object[]{livestockId, farmId});
        }
    }

    private void recordAudit(String action, Long tenantId, Long operatorId, Map<String, Object> details) {
        auditLogRepository.save(new AuditLog(UUID.randomUUID().toString(), action, tenantId,
                operatorId, action, details, Instant.now()));
    }

    private ApiException hubUnavailable(FeignException e) {
        log.warn("[DeviceHub] service call failed: {}", e.getMessage());
        return new ApiException(ErrorCode.INTERNAL_ERROR, "iot.devicehub.unavailable",
                new Object[]{e.getMessage()});
    }

    private static String requireEui(String eui) {
        String normalized = TbDeviceProvisioningService.normalizeEui(eui);
        if (!EUI_PATTERN.matcher(normalized).matches()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "iot.invalidEuiFormat", new Object[]{eui});
        }
        return normalized;
    }
}
