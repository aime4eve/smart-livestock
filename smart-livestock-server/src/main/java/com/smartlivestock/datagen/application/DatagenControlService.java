package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.DatagenOperatorContext.DatagenOperatorRole;
import com.smartlivestock.datagen.application.dto.*;
import com.smartlivestock.datagen.domain.model.DatagenDeviceAssignment;
import com.smartlivestock.datagen.domain.model.DatagenFarmControl;
import com.smartlivestock.datagen.domain.model.DatagenFarmRules;
import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import com.smartlivestock.datagen.domain.repository.DatagenDeviceAssignmentRepository;
import com.smartlivestock.datagen.domain.repository.DatagenFarmControlRepository;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.model.Tenant;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DatagenControlService {
    private static final String DEFAULT_SCENARIO_NAME = "默认持续合成";
    private static final String STATS_TIME_ZONE = "Asia/Shanghai";

    private final FarmRepository farmRepository;
    private final TenantRepository tenantRepository;
    private final AuditLogRepository auditLogRepository;
    private final DeviceRepository deviceRepository;
    private final InstallationRepository installationRepository;
    private final LivestockRepository livestockRepository;
    private final SynthesisScenarioRepository scenarioRepository;
    private final DatagenFarmControlRepository controlRepository;
    private final DatagenDeviceAssignmentRepository assignmentRepository;
    private final DatagenFarmAccessService accessService;
    private final DatagenOperatorContextResolver operatorResolver;
    private final DatagenDataQueryService dataQueryService;
    private final DatagenAuditService auditService;
    private final SynthesisService synthesisService;

    @Transactional(readOnly = true)
    public List<DatagenFarmDto> listFarms() {
        DatagenOperatorContext operator = operatorResolver.resolve();
        List<Farm> farms = operator.isPlatformAdmin()
                ? farmRepository.findAll()
                : farmRepository.findByTenantId(operator.tenantId());

        return farms.stream()
                .map(farm -> {
                    DatagenFarmControl control = controlRepository
                            .findByFarmId(farm.getId()).orElse(null);
                    int selectedCount = control == null ? 0
                            : assignmentRepository.findActiveByControlId(control.getId()).size();
                    String tenantName = tenantRepository.findById(farm.getTenantId())
                            .map(Tenant::getName).orElse("");
                    return new DatagenFarmDto(
                            farm.getId(), farm.getName(), farm.getTenantId(), tenantName,
                            control != null && control.isEnabled(), selectedCount);
                })
                .toList();
    }

    @Transactional
    public DatagenConsoleDto getConsole(Long farmId) {
        DatagenOperatorContext operator = operatorResolver.resolve();
        Farm farm = accessService.requireAccessibleFarm(farmId, operator);
        SynthesisScenario scenario = defaultScenario();
        DatagenFarmControl control = controlRepository.ensureByFarmId(
                farm.getTenantId(), farm.getId(), scenario.getId());

        List<DatagenDeviceDto> devices = buildDevices(farm, control);
        List<DatagenDeviceAssignment> assignments =
                assignmentRepository.findByControlId(control.getId());
        List<Long> assignedDeviceIds = assignments.stream()
                .map(DatagenDeviceAssignment::getDeviceId).distinct().toList();
        List<Long> activeDeviceIds = assignments.stream()
                .filter(DatagenDeviceAssignment::isActive)
                .map(DatagenDeviceAssignment::getDeviceId).toList();

        DatagenDataQueryService.DatagenStatsParts parts = dataQueryService.statsByDeviceIds(
                assignedDeviceIds, dataQueryService.todayStart(), Instant.now());
        int trackerCount = (int) activeDeviceIds.stream()
                .filter(id -> deviceRepository.findById(id)
                        .filter(device -> device.getDeviceType() == DeviceType.TRACKER)
                        .isPresent())
                .count();
        DatagenStatsDto stats = new DatagenStatsDto(
                STATS_TIME_ZONE,
                activeDeviceIds.size(),
                trackerCount,
                activeDeviceIds.size() - trackerCount,
                parts.telemetryRows(),
                parts.gpsRows(),
                parts.temperatureRows() + parts.motilityRows() + parts.activityRows(),
                dataQueryService.lastGeneratedAt(assignedDeviceIds));

        String tenantName = tenantRepository.findById(farm.getTenantId())
                .map(Tenant::getName).orElse("");
        DatagenFarmDto farmDto = new DatagenFarmDto(
                farm.getId(), farm.getName(), farm.getTenantId(), tenantName,
                control.isEnabled(), activeDeviceIds.size());
        DatagenScenarioDto scenarioDto =
                new DatagenScenarioDto(scenario.getId(), scenario.getName(), scenario.getType().getDbValue());
        return new DatagenConsoleDto(
                farmDto, control.isEnabled(), scenarioDto, rulesDto(control.getRules()),
                devices, stats, operations(farm.getId()));
    }

    @Transactional
    public DatagenControlResponse updateControl(
            Long farmId, DatagenControlRequest request) {
        DatagenOperatorContext operator = operatorResolver.resolve();
        Farm farm = accessService.requireAccessibleFarm(farmId, operator);
        SynthesisScenario scenario = defaultScenario();
        DatagenFarmControl control = controlRepository.ensureByFarmId(
                farm.getTenantId(), farm.getId(), scenario.getId());

        List<Long> requested = request.deviceIds() == null
                ? List.of() : request.deviceIds().stream().distinct().toList();
        if (request.enabled() && requested.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "error.datagen.devicesRequired");
        }
        validateDevices(farm, requested);

        List<DatagenDeviceAssignment> assignments =
                assignmentRepository.findByControlId(control.getId());
        Map<Long, DatagenDeviceAssignment> byDevice = assignments.stream()
                .collect(Collectors.toMap(
                        DatagenDeviceAssignment::getDeviceId, assignment -> assignment));
        Set<Long> requestedSet = new HashSet<>(requested);
        for (Long deviceId : requestedSet) {
            DatagenDeviceAssignment assignment = byDevice.get(deviceId);
            if (assignment == null) {
                assignment = new DatagenDeviceAssignment();
                assignment.setControlId(control.getId());
                assignment.setDeviceId(deviceId);
                assignment.setFirstAssignedAt(Instant.now());
                byDevice.put(deviceId, assignment);
                assignments.add(assignment);
            }
            assignment.activate();
        }
        for (DatagenDeviceAssignment assignment : assignments) {
            if (!requestedSet.contains(assignment.getDeviceId()) && assignment.isActive()) {
                assignment.deactivate(Instant.now());
            }
        }

        boolean wasEnabled = control.isEnabled();
        if (request.enabled()) {
            ensureScenarioRunnable(scenario);
            control.enable();
            synthesisService.clearDeviceSchedules(requestedSet);
        } else {
            control.disable();
        }

        controlRepository.save(control);
        assignmentRepository.saveAll(assignments);
        String action = request.enabled() != wasEnabled
                ? (request.enabled() ? "START" : "STOP") : "UPDATE_DEVICES";
        auditService.record(action, farm.getId(), operator, Map.of(
                "enabled", request.enabled(),
                "deviceIds", requested,
                "deviceCount", requested.size()));
        return new DatagenControlResponse(farm.getId(), request.enabled(), requested.size());
    }

    @Transactional
    public DatagenRulesDto updateRules(Long farmId, DatagenRulesDto request) {
        DatagenOperatorContext operator = operatorResolver.resolve();
        Farm farm = accessService.requireAccessibleFarm(farmId, operator);
        SynthesisScenario scenario = defaultScenario();
        DatagenFarmControl control = controlRepository.ensureByFarmId(
                farm.getTenantId(), farm.getId(), scenario.getId());
        validateRules(request);

        DatagenFarmRules rules = new DatagenFarmRules(
                request.trackerIntervalSeconds(),
                request.capsuleIntervalSeconds(),
                request.fenceExcursionProbability(),
                request.fenceExcursionMinMinutes(),
                request.fenceExcursionMaxMinutes(),
                request.healthEventProbability(),
                request.feverDurationMinMinutes(),
                request.feverDurationMaxMinutes(),
                request.motilityDurationMinMinutes(),
                request.motilityDurationMaxMinutes());
        control.setRules(rules);
        controlRepository.save(control);

        List<Long> activeDeviceIds = assignmentRepository
                .findActiveByControlId(control.getId()).stream()
                .map(DatagenDeviceAssignment::getDeviceId)
                .toList();
        synthesisService.clearDeviceSchedules(activeDeviceIds);

        auditService.record("UPDATE_RULES", farm.getId(), operator, Map.of(
                "rules", rulesDto(rules)));
        return rulesDto(rules);
    }

    private void validateRules(DatagenRulesDto rules) {
        if (rules == null
                || rules.trackerIntervalSeconds() < 60 || rules.trackerIntervalSeconds() > 3600
                || rules.capsuleIntervalSeconds() < 300 || rules.capsuleIntervalSeconds() > 7200
                || rules.fenceExcursionProbability() < 0 || rules.fenceExcursionProbability() > 0.2
                || rules.fenceExcursionMinMinutes() < 5 || rules.fenceExcursionMinMinutes() > 120
                || rules.fenceExcursionMaxMinutes() < 5 || rules.fenceExcursionMaxMinutes() > 120
                || rules.fenceExcursionMinMinutes() > rules.fenceExcursionMaxMinutes()
                || rules.healthEventProbability() < 0 || rules.healthEventProbability() > 0.1
                || rules.feverDurationMinMinutes() < 120 || rules.feverDurationMinMinutes() > 1440
                || rules.feverDurationMaxMinutes() < 120 || rules.feverDurationMaxMinutes() > 1440
                || rules.feverDurationMinMinutes() > rules.feverDurationMaxMinutes()
                || rules.motilityDurationMinMinutes() < 120 || rules.motilityDurationMinMinutes() > 1440
                || rules.motilityDurationMaxMinutes() < 120 || rules.motilityDurationMaxMinutes() > 1440
                || rules.motilityDurationMinMinutes() > rules.motilityDurationMaxMinutes()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "error.datagen.invalidRules");
        }
    }

    private DatagenRulesDto rulesDto(DatagenFarmRules rules) {
        return new DatagenRulesDto(
                rules.trackerIntervalSeconds(),
                rules.capsuleIntervalSeconds(),
                rules.fenceExcursionProbability(),
                rules.fenceExcursionMinMinutes(),
                rules.fenceExcursionMaxMinutes(),
                rules.healthEventProbability(),
                rules.feverDurationMinMinutes(),
                rules.feverDurationMaxMinutes(),
                rules.motilityDurationMinMinutes(),
                rules.motilityDurationMaxMinutes());
    }

    private List<DatagenDeviceDto> buildDevices(Farm farm, DatagenFarmControl control) {
        List<Livestock> livestockList = livestockRepository.findByFarmId(farm.getId());
        Set<Long> deviceIds = new LinkedHashSet<>();
        for (Livestock livestock : livestockList) {
            installationRepository.findByLivestockId(livestock.getId()).forEach(
                    installation -> deviceIds.add(installation.getDeviceId()));
        }
        Set<Long> selectedIds = assignmentRepository
                .findActiveByControlId(control.getId()).stream()
                .map(DatagenDeviceAssignment::getDeviceId)
                .collect(Collectors.toSet());
        Map<Long, Instant> lastGenerated = dataQueryService.lastGeneratedByDevice(
                deviceIds.stream().toList());

        List<DatagenDeviceDto> result = new ArrayList<>();
        for (Long deviceId : deviceIds) {
            Device device = deviceRepository.findById(deviceId).orElse(null);
            if (device == null || device.getDeviceType() == null
                    || (device.getDeviceType() != DeviceType.TRACKER
                    && device.getDeviceType() != DeviceType.CAPSULE)) {
                continue;
            }
            Installation installation = installationRepository
                    .findActiveByDeviceId(deviceId).orElse(null);
            Livestock livestock = installation == null ? null
                    : livestockRepository.findById(installation.getLivestockId()).orElse(null);
            boolean eligible = device.getStatus() == DeviceStatus.ACTIVE
                    && device.getDeletedAt() == null
                    && livestock != null
                    && farm.getId().equals(livestock.getFarmId());
            result.add(new DatagenDeviceDto(
                    device.getId(), device.getDeviceCode(), device.getDevEui(),
                    device.getDeviceType().name(),
                    livestock != null ? livestock.getId() : null,
                    livestock != null ? livestock.getLivestockCode() : null,
                    device.getRuntimeStatus(),
                    selectedIds.contains(deviceId),
                    eligible,
                    eligible ? null : "error.datagen.deviceInvalid",
                    lastGenerated.get(deviceId)));
        }
        return result;
    }

    private void validateDevices(Farm farm, List<Long> deviceIds) {
        for (Long deviceId : deviceIds) {
            Device device = deviceRepository.findById(deviceId).orElse(null);
            if (device == null || device.getDeletedAt() != null
                    || device.getStatus() != DeviceStatus.ACTIVE
                    || (device.getDeviceType() != DeviceType.TRACKER
                    && device.getDeviceType() != DeviceType.CAPSULE)) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "error.datagen.deviceInvalid", new Object[]{deviceId});
            }
            Installation installation = installationRepository
                    .findActiveByDeviceId(deviceId).orElse(null);
            Livestock livestock = installation == null ? null
                    : livestockRepository.findById(installation.getLivestockId()).orElse(null);
            if (livestock == null || !farm.getId().equals(livestock.getFarmId())) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "error.datagen.deviceInvalid", new Object[]{deviceId});
            }
        }
    }

    private SynthesisScenario defaultScenario() {
        SynthesisScenario scenario = scenarioRepository
                .findFirstByNameOrderById(DEFAULT_SCENARIO_NAME)
                .orElseGet(() -> {
                    SynthesisScenario created = new SynthesisScenario();
                    created.setName(DEFAULT_SCENARIO_NAME);
                    created.setType(com.smartlivestock.datagen.domain.model.ScenarioType.NORMAL);
                    created.setStatus(ScenarioStatus.RUNNING);
                    created.setPenetrationRate(1.0);
                    created.setWindowStart(Instant.now());
                    created.setWindowEnd(Instant.now().plusSeconds(365 * 24 * 3600));
                    created.setIntervalSeconds(30);
                    return scenarioRepository.save(created);
                });
        ensureScenarioRunnable(scenario);
        return scenarioRepository.save(scenario);
    }

    private void ensureScenarioRunnable(SynthesisScenario scenario) {
        if (scenario.getStatus() != ScenarioStatus.RUNNING) {
            scenario.start();
        }
        if (scenario.getWindowEnd() == null || !scenario.getWindowEnd().isAfter(Instant.now())) {
            scenario.setWindowEnd(Instant.now().plusSeconds(365 * 24 * 3600));
        }
    }

    private List<DatagenOperationDto> operations(Long farmId) {
        return auditLogRepository.findByFarmIdOrderByOccurredAtDesc(farmId, 10).stream()
                .map(audit -> new DatagenOperationDto(
                        audit.getId(), audit.getAction(), audit.getUserId(),
                        audit.getOperatorRole(), audit.getOccurredAt(),
                        summaryKey(audit.getAction(), audit.getDetails())))
                .toList();
    }

    private String summaryKey(String action, Map<String, Object> details) {
        if (details != null && details.get("summaryKey") instanceof String key) {
            return key;
        }
        return action == null ? "" : action;
    }
}
