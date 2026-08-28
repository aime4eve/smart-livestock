package com.smartlivestock.iot.application;

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
import com.smartlivestock.iot.infrastructure.client.ns.NsClient;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbClient;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class TbDeviceProvisioningService {

    private static final Pattern EUI_PATTERN = Pattern.compile("^[0-9a-f]{16}$");
    private static final String CAPSULE_PROFILE = "瘤胃胶囊-OC-配置-v2";
    private static final String TRACKER_PROFILE = "牛羊追踪器-OC-配置-v2";

    private final NsClient nsClient;
    private final TbClient tbClient;
    private final DeviceRepository deviceRepository;
    private final TbDeviceBindingRepository bindingRepository;
    private final InstallationRepository installationRepository;
    private final AuditLogRepository auditLogRepository;
    private final RanchQueryPort ranchQueryPort;

    @Transactional(readOnly = true)
    public ReconciliationReport reconcile(Integer nsProjectId, Long tenantId) {
        List<NsClient.NsDevice> nsDevices = nsClient.listDevices(nsProjectId);
        Map<String, String> profiles = tbClient.fetchDeviceProfiles();
        List<ReconciliationRow> rows = new ArrayList<>();

        for (NsClient.NsDevice nsDevice : nsDevices) {
            String eui = normalizeEui(nsDevice.eui());
            TbInventory tb = tbInventory(eui, profiles);
            LocalInventory local = localInventory(eui, tenantId);
            Instant latestTelemetry = tb.selected() == null ? null
                    : tbClient.fetchLatestTelemetryTs(tb.selected().tbDeviceId());

            List<String> differences = new ArrayList<>();
            if (tb.views().isEmpty()) differences.add("TB_MISSING");
            if (tb.views().size() > 1) differences.add("TB_AMBIGUOUS");
            if (tb.selected() != null && !tb.selected().profileValid()) differences.add("PROFILE_MISMATCH");
            if (local.device() == null) differences.add("LOCAL_MISSING");
            if (local.softDeleted()) differences.add("LOCAL_SOFT_DELETED");
            boolean localUsable = local.device() != null && !local.softDeleted();
            boolean bindingMatches = localUsable && local.binding() != null
                    && tb.selected() != null
                    && tb.selected().tbDeviceId().equals(local.binding().getExternalDeviceId());
            if (localUsable && tb.selected() != null
                    && local.device().getDeviceType() != tb.selected().deviceType()) {
                differences.add("LOCAL_TYPE_MISMATCH");
            }
            if (localUsable && local.device().getStatus() != DeviceStatus.ACTIVE) {
                differences.add("LOCAL_DEVICE_NOT_ACTIVE");
            }
            if (localUsable && (local.binding() == null
                    || local.binding().getStatus() != TbDeviceBinding.Status.RESOLVED)) {
                differences.add("BINDING_MISSING");
            }
            if (localUsable && local.binding() != null && !bindingMatches) {
                differences.add("TB_IDENTITY_CONFLICT");
            }
            if (latestTelemetry == null) differences.add("NO_RECENT_TELEMETRY");
            if (local.device() != null && !local.softDeleted() && local.installation() == null) {
                differences.add("NO_ACTIVE_INSTALLATION");
            }
            if (differences.isEmpty()) differences.add("RECONCILED");

            boolean importable = tb.selected() != null && tb.selected().profileValid()
                    && !local.softDeleted()
                    && (local.device() == null
                        || (local.device().getDeviceType() == tb.selected().deviceType()
                            && local.device().getStatus() == DeviceStatus.ACTIVE))
                    && (local.binding() == null
                        || local.binding().getStatus() != TbDeviceBinding.Status.RESOLVED
                        || !bindingMatches);
            rows.add(new ReconciliationRow(
                    eui, nsDevice.projectId(), nsDevice.appId(), nsDevice.name(),
                    tb.candidates(), latestTelemetry,
                    local.device() == null ? null : local.device().getId(),
                    local.device() == null ? null : local.device().getDeviceCode(),
                    local.device() == null ? null : local.device().getDeviceType(),
                    local.binding() == null ? null : local.binding().getId(),
                    local.binding() == null ? null : local.binding().getStatus().name(),
                    local.installation() != null,
                    differences, importable, actionFor(importable, local)));
        }

        long resolvedBindings = rows.stream()
                .filter(row -> "RESOLVED".equals(row.bindingStatus()))
                .count();
        long activeInstallations = rows.stream()
                .filter(ReconciliationRow::activeInstallation)
                .count();
        return new ReconciliationReport(
                nsProjectId,
                "NS_PROJECT_DEVICE_LIST_API",
                List.of(
                        "PROJECT_NAME_IS_NOT_INVENTORY_FACT",
                        "TB_GATEWAY_MAPPING_NOT_READ_OR_CHANGED"),
                rows,
                new ReconciliationCounts(
                        rows.size(),
                        rows.stream().filter(row -> row.tbCandidates().size() == 1).count(),
                        rows.stream().filter(row -> row.localDeviceId() != null).count(),
                        resolvedBindings,
                        activeInstallations));
    }

    @Transactional
    public ImportReport importDevices(
            Integer nsProjectId, List<ImportItem> items, Long tenantId, Long operatorId) {
        Map<String, NsClient.NsDevice> nsByEui = nsDeviceMap(nsProjectId);
        Map<String, String> profiles = tbClient.fetchDeviceProfiles();
        List<ImportResult> results = new ArrayList<>();
        for (ImportItem item : items) {
            results.add(importDevice(item, nsByEui, profiles, tenantId, operatorId, nsProjectId));
        }
        return new ImportReport(nsProjectId, results);
    }

    @Transactional(readOnly = true)
    public Preflight preflight(String eui, Long tenantId) {
        String normalized = requireEui(eui);
        NsClient.NsDevice nsDevice = nsClient.listDevices(null).stream()
                .filter(item -> normalizeEui(item.eui()).equals(normalized))
                .findFirst().orElse(null);
        TbInventory tb = tbInventory(normalized, tbClient.fetchDeviceProfiles());
        LocalInventory local = localInventory(normalized, tenantId);
        Instant latestTelemetry = tb.selected() == null ? null
                : tbClient.fetchLatestTelemetryTs(tb.selected().tbDeviceId());

        boolean localDeviceUsable = local.device() != null && !local.softDeleted()
                && tb.selected() != null
                && local.device().getDeviceType() == tb.selected().deviceType()
                && local.device().getStatus() == DeviceStatus.ACTIVE;
        boolean localBindingUsable = localDeviceUsable && local.binding() != null
                && local.binding().getStatus() == TbDeviceBinding.Status.RESOLVED
                && local.binding().getExternalDeviceId().equals(tb.selected().tbDeviceId());
        String status;
        if (nsDevice == null) status = "PENDING_NS";
        else if (tb.selected() == null || !tb.selected().profileValid()) status = "PENDING_TB_DEVICE";
        else if (latestTelemetry == null) status = "PENDING_TELEMETRY";
        else if (!localDeviceUsable || !localBindingUsable) status = "READY_TO_INGEST";
        else if (local.installation() == null) status = "PENDING_INSTALLATION";
        else status = "ACTIVE";

        return new Preflight(
                normalized, status, nsDevice, tb.candidates(), latestTelemetry,
                local.device() == null ? null : local.device().getId(),
                local.device() == null ? null : local.device().getDeviceCode(),
                local.device() == null ? null : local.device().getDeviceType(),
                local.binding() == null ? null : local.binding().getStatus().name(),
                local.installation() != null);
    }

    @Transactional
    public ProvisionResult provision(
            ProvisionCommand command, Long tenantId, Long farmId, Long operatorId) {
        String eui = requireEui(command.eui());
        NsClient.NsDevice nsDevice = nsClient.listDevices(null).stream()
                .filter(item -> normalizeEui(item.eui()).equals(eui))
                .findFirst().orElseThrow(() -> new ApiException(
                        ErrorCode.VALIDATION_ERROR, "iot.tb.nsDeviceMissing", new Object[]{eui}));
        TbInventory tb = tbInventory(eui, tbClient.fetchDeviceProfiles());
        if (tb.selected() == null || !tb.selected().profileValid()) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.tb.deviceNotImportable", new Object[]{eui});
        }
        if (command.deviceType() != null && command.deviceType() != tb.selected().deviceType()) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.tb.deviceTypeMismatch", new Object[]{eui});
        }
        validateLivestock(farmId, command.livestockId());

        LocalInventory local = localInventory(eui, tenantId);
        if (local.softDeleted()) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.tb.localDeviceSoftDeleted", new Object[]{eui});
        }
        Device device = local.device();
        boolean deviceCreated = false;
        if (device == null) {
            String deviceCode = command.deviceCode();
            if (deviceCode == null || deviceCode.isBlank()) {
                deviceCode = "TB-" + nsDevice.projectId() + "-" + eui;
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
            device.setDeviceType(tb.selected().deviceType());
            device = deviceRepository.save(device);
            deviceCreated = true;
        } else if (device.getDeviceType() != tb.selected().deviceType()) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.tb.deviceTypeMismatch", new Object[]{eui});
        }
        if (device.getStatus() == DeviceStatus.INVENTORY) {
            device.activate();
            device = deviceRepository.save(device);
        } else if (device.getStatus() != DeviceStatus.ACTIVE) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "error.deviceNotActiveForInstall", new Object[]{device.getId()});
        }

        TbDeviceBinding binding = bindingRepository
                .findByProviderAndExternalDeviceId(TbDeviceBinding.PROVIDER_THINGSBOARD,
                        tb.selected().tbDeviceId())
                .orElse(null);
        if (binding != null && !binding.getDeviceId().equals(device.getId())) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.tb.bindingIdentityConflict",
                    new Object[]{tb.selected().tbDeviceId()});
        }
        boolean bindingCreated = false;
        if (binding == null) {
            binding = bindingRepository.findByDeviceIdAndProvider(
                            device.getId(), TbDeviceBinding.PROVIDER_THINGSBOARD)
                    .orElseGet(TbDeviceBinding::new);
            bindingCreated = binding.getId() == null;
        }
        if (binding.getId() != null && !Objects.equals(
                binding.getExternalDeviceId(), tb.selected().tbDeviceId())) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.tb.bindingIdentityConflict",
                    new Object[]{tb.selected().tbDeviceId()});
        }
        binding.setTenantId(tenantId);
        binding.setDeviceId(device.getId());
        binding.setProvider(TbDeviceBinding.PROVIDER_THINGSBOARD);
        binding.setDeviceEui(eui);
        binding.setExternalDeviceId(tb.selected().tbDeviceId());
        binding.setExternalDeviceName(tb.selected().tbDeviceName());
        binding.setStatus(TbDeviceBinding.Status.RESOLVED);
        binding.setLastVerifiedAt(Instant.now());
        binding = bindingRepository.save(binding);

        boolean installationCreated = false;
        if (command.livestockId() != null) {
            Installation existing = installationRepository.findActiveByDeviceId(device.getId()).orElse(null);
            if (existing == null) {
                Installation installation = new Installation(
                        device.getId(), command.livestockId(), operatorId);
                installationRepository.save(installation);
                installationCreated = true;
            } else if (!existing.getLivestockId().equals(command.livestockId())) {
                throw new ApiException(ErrorCode.STATE_CONFLICT,
                        "error.deviceAlreadyInstalled", new Object[]{device.getId()});
            }
        }

        recordAudit("TB_DEVICE_PROVISIONED", tenantId, operatorId, Map.of(
                "nsProjectId", nsDevice.projectId(),
                "eui", eui,
                "tbDeviceId", tb.selected().tbDeviceId(),
                "tbProfile", String.valueOf(tb.selected().profileName()),
                "localDeviceId", device.getId(),
                "deviceCreated", deviceCreated,
                "bindingCreated", bindingCreated,
                "installationCreated", installationCreated,
                "livestockId", command.livestockId() == null ? "" : command.livestockId()));
        return new ProvisionResult(eui, device.getId(), device.getDeviceCode(),
                device.getStatus().name(), binding.getId(), binding.getStatus().name(),
                command.livestockId(), installationCreated, tb.selected().deviceType().name());
    }

    private ImportResult importDevice(
            ImportItem item, Map<String, NsClient.NsDevice> nsByEui,
            Map<String, String> profiles, Long tenantId, Long operatorId, Integer nsProjectId) {
        String eui = requireEui(item.eui());
        String result = "IMPORTED";
        Long localDeviceId = null;
        Long bindingId = null;
        try {
            NsClient.NsDevice nsDevice = nsByEui.get(eui);
            if (nsDevice == null) {
                result = "SKIPPED_NS_MISSING";
                return new ImportResult(eui, item.expectedTbDeviceId(), null, null, result);
            }
            TbInventory tb = tbInventory(eui, profiles);
            if (tb.selected() == null || !tb.selected().profileValid()) {
                result = tb.views().size() > 1 ? "SKIPPED_TB_AMBIGUOUS" : "SKIPPED_TB_INVALID";
                return new ImportResult(eui, item.expectedTbDeviceId(), null, null, result);
            }
            if (item.expectedTbDeviceId() != null
                    && !item.expectedTbDeviceId().equals(tb.selected().tbDeviceId())) {
                result = "SKIPPED_TB_ID_CHANGED";
                return new ImportResult(eui, item.expectedTbDeviceId(), null, null, result);
            }

            LocalInventory local = localInventory(eui, tenantId);
            if (local.softDeleted()) {
                result = "SKIPPED_LOCAL_SOFT_DELETED";
                return new ImportResult(eui, tb.selected().tbDeviceId(), null, null, result);
            }
            Device device = local.device();
            if (device == null) {
                String deviceCode = item.deviceCode();
                if (deviceCode == null || deviceCode.isBlank()) {
                    deviceCode = "TB-" + nsProjectId + "-" + eui;
                }
                if (deviceRepository.findByDeviceCode(deviceCode).isPresent()) {
                    result = "SKIPPED_DEVICE_CODE_DUPLICATE";
                    return new ImportResult(eui, tb.selected().tbDeviceId(), null, null, result);
                }
                device = new Device();
                device.setTenantId(tenantId);
                device.setDeviceCode(deviceCode);
                device.setSerialNo(eui);
                device.setDevEui(eui);
                device.setDeviceType(tb.selected().deviceType());
                device = deviceRepository.save(device);
                device.activate();
                device = deviceRepository.save(device);
            } else if (device.getDeviceType() != tb.selected().deviceType()) {
                result = "SKIPPED_TYPE_MISMATCH";
                return new ImportResult(eui, tb.selected().tbDeviceId(), device.getId(), null, result);
            } else if (device.getStatus() == DeviceStatus.INVENTORY) {
                device.activate();
                device = deviceRepository.save(device);
            } else if (device.getStatus() != DeviceStatus.ACTIVE) {
                result = "SKIPPED_LOCAL_DEVICE_NOT_ACTIVE";
                return new ImportResult(eui, tb.selected().tbDeviceId(), device.getId(), null, result);
            }
            localDeviceId = device.getId();

            TbDeviceBinding externalBinding = bindingRepository.findByProviderAndExternalDeviceId(
                    TbDeviceBinding.PROVIDER_THINGSBOARD, tb.selected().tbDeviceId()).orElse(null);
            if (externalBinding != null && !externalBinding.getDeviceId().equals(device.getId())) {
                result = "SKIPPED_BINDING_IDENTITY_CONFLICT";
                return new ImportResult(eui, tb.selected().tbDeviceId(), device.getId(), null, result);
            }
            TbDeviceBinding binding = externalBinding != null ? externalBinding
                    : bindingRepository.findByDeviceIdAndProvider(
                            device.getId(), TbDeviceBinding.PROVIDER_THINGSBOARD).orElse(null);
            if (binding != null && !Objects.equals(binding.getExternalDeviceId(), tb.selected().tbDeviceId())) {
                result = "SKIPPED_BINDING_IDENTITY_CONFLICT";
                return new ImportResult(eui, tb.selected().tbDeviceId(), device.getId(), binding.getId(), result);
            }
            if (binding == null) {
                binding = new TbDeviceBinding();
            } else {
                result = "ALREADY_BOUND";
            }
            binding.setTenantId(tenantId);
            binding.setDeviceId(device.getId());
            binding.setProvider(TbDeviceBinding.PROVIDER_THINGSBOARD);
            binding.setDeviceEui(eui);
            binding.setExternalDeviceId(tb.selected().tbDeviceId());
            binding.setExternalDeviceName(tb.selected().tbDeviceName());
            binding.setStatus(TbDeviceBinding.Status.RESOLVED);
            binding.setLastVerifiedAt(Instant.now());
            binding = bindingRepository.save(binding);
            bindingId = binding.getId();
            return new ImportResult(eui, tb.selected().tbDeviceId(), device.getId(), bindingId, result);
        } finally {
            recordAudit("TB_DEVICE_IMPORTED", tenantId, operatorId, Map.of(
                    "nsProjectId", nsProjectId == null ? "" : nsProjectId,
                    "eui", eui,
                    "tbDeviceId", item.expectedTbDeviceId() == null ? "" : item.expectedTbDeviceId(),
                    "localDeviceId", localDeviceId == null ? "" : localDeviceId,
                    "bindingId", bindingId == null ? "" : bindingId,
                    "result", result));
        }
    }

    private TbInventory tbInventory(String eui, Map<String, String> profiles) {
        List<TbCandidate> candidates = tbClient.findDevices(eui).stream()
                .map(view -> {
                    String profileName = profiles.getOrDefault(view.profileId(), "");
                    DeviceType type = deviceTypeForProfile(profileName);
                    return new TbCandidate(view.id(), view.name(), view.profileId(), profileName,
                            type, type != null);
                }).toList();
        TbCandidate selected = candidates.size() == 1 ? candidates.get(0) : null;
        return new TbInventory(candidates, selected);
    }

    private LocalInventory localInventory(String eui, Long tenantId) {
        List<Device> matches = deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(eui, tenantId);
        Device active = matches.stream().filter(device -> device.getDeletedAt() == null).findFirst().orElse(null);
        Device softDeleted = matches.stream().filter(device -> device.getDeletedAt() != null).findFirst().orElse(null);
        TbDeviceBinding binding = active == null ? null : bindingRepository
                .findByDeviceIdAndProvider(active.getId(), TbDeviceBinding.PROVIDER_THINGSBOARD).orElse(null);
        Installation installation = active == null ? null : installationRepository
                .findActiveByDeviceId(active.getId()).orElse(null);
        return new LocalInventory(active, softDeleted != null, binding, installation);
    }

    private Map<String, NsClient.NsDevice> nsDeviceMap(Integer nsProjectId) {
        Map<String, NsClient.NsDevice> result = new LinkedHashMap<>();
        for (NsClient.NsDevice device : nsClient.listDevices(nsProjectId)) {
            result.putIfAbsent(normalizeEui(device.eui()), device);
        }
        return result;
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

    private static String actionFor(boolean importable, LocalInventory local) {
        if (!importable) return "RESOLVE_MANUALLY";
        if (local.device() == null) return "CREATE_DEVICE_AND_BINDING";
        return "CREATE_BINDING";
    }

    public static String normalizeEui(String eui) {
        return eui == null ? "" : eui.trim().toLowerCase(Locale.ROOT);
    }

    private static String requireEui(String eui) {
        String normalized = normalizeEui(eui);
        if (!EUI_PATTERN.matcher(normalized).matches()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "iot.invalidEuiFormat", new Object[]{eui});
        }
        return normalized;
    }

    private static DeviceType deviceTypeForProfile(String profileName) {
        if (CAPSULE_PROFILE.equals(profileName)) return DeviceType.CAPSULE;
        if (TRACKER_PROFILE.equals(profileName)) return DeviceType.TRACKER;
        return null;
    }

    public record ImportItem(String eui, String expectedTbDeviceId, String deviceCode) {}

    public record ProvisionCommand(
            String eui, String deviceCode, DeviceType deviceType, Long livestockId) {}

    public record TbCandidate(
            String tbDeviceId, String tbDeviceName, String profileId, String profileName,
            DeviceType deviceType, boolean profileValid) {}

    public record ReconciliationRow(
            String eui, Integer nsProjectId, Integer nsAppId, String nsName,
            List<TbCandidate> tbCandidates, Instant latestTelemetryAt,
            Long localDeviceId, String localDeviceCode, DeviceType localDeviceType,
            Long bindingId, String bindingStatus, boolean activeInstallation,
            List<String> differenceCodes, boolean importable, String action) {}

    public record ReconciliationCounts(
            long nsCount, long tbUniqueCount, long localCount,
            long resolvedBindingCount, long activeInstallationCount) {}

    public record ReconciliationReport(
            Integer nsProjectId, String factSource, List<String> notes,
            List<ReconciliationRow> rows, ReconciliationCounts counts) {}

    public record ImportResult(
            String eui, String expectedTbDeviceId, Long localDeviceId,
            Long bindingId, String result) {}

    public record ImportReport(Integer nsProjectId, List<ImportResult> results) {}

    public record Preflight(
            String eui, String status, NsClient.NsDevice nsDevice,
            List<TbCandidate> tbCandidates, Instant latestTelemetryAt,
            Long localDeviceId, String localDeviceCode, DeviceType localDeviceType,
            String bindingStatus, boolean activeInstallation) {}

    public record ProvisionResult(
            String eui, Long localDeviceId, String deviceCode, String deviceStatus,
            Long bindingId, String bindingStatus, Long livestockId,
            boolean installationCreated, String deviceType) {}

    private record TbInventory(List<TbCandidate> candidates, TbCandidate selected) {
        private List<TbCandidate> views() {
            return candidates;
        }
    }

    private record LocalInventory(
            Device device, boolean softDeleted, TbDeviceBinding binding, Installation installation) {}
}
