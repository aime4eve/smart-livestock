package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.event.TelemetryReceivedEvent;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.GpsIngestionTask;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.GpsIngestionTaskRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.iot.domain.service.GpsDistanceDerivationService;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Unified telemetry ingestion service (Phase 3 upgrade — 分流+透传 mode).
 * <p>
 * All data sources (agentic-middle-platform polling / datagen synthesis / HTTP push)
 * go through a single ingest() method that:
 * <ol>
 *   <li>Updates device runtime status snapshot (devices table)</li>
 *   <li>Writes device operational timeseries (device_telemetry_logs)</li>
 *   <li>Enqueues GPS writes for TRACKER devices (durable outbox)</li>
 *   <li>Detects device alerts (tamper / low battery) for live platform sources</li>
 *   <li>Publishes TelemetryReceivedEvent for cross-context consumption</li>
 *   <li>Advances sync cursor — only for AGENTIC_PLATFORM source</li>
 * </ol>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TelemetryIngestionService {

    private final DeviceRepository deviceRepository;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final InstallationRepository installationRepository;
    private final RanchQueryPort ranchQueryPort;
    private final GpsIngestionTaskRepository gpsIngestionTaskRepository;
    private final AlertRepository alertRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final GpsDistanceDerivationService gpsDistanceDerivationService;
    private final ObjectMapper objectMapper;

    /**
     * Ingest telemetry data from any source (Phase 3 unified entry point).
     *
     * @param deviceId   the device reporting telemetry
     * @param readings   map of sensor readings using standard keys (see spec §6.2)
     * @param recordedAt timestamp of the reading
     * @param source     telemetry data source
     */
    @Transactional
    public void ingest(Long deviceId, Map<String, Object> readings,
                       Instant recordedAt, TelemetrySource source) {
        Instant effectiveRecordedAt = recordedAt != null ? recordedAt : Instant.now();
        readings = new HashMap<>(readings);

        Device device = deviceRepository.findById(deviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "设备不存在: " + deviceId));

        if (device.getStatus() != DeviceStatus.ACTIVE) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "设备未激活: " + device.getStatus());
        }

        // Resolve installation + farm context
        Long livestockId = null;
        Long farmId = null;
        Installation installation = installationRepository.findActiveByDeviceId(deviceId).orElse(null);
        if (installation != null) {
            livestockId = installation.getLivestockId();
            LivestockInfo livestock = ranchQueryPort.findLivestockById(livestockId).orElse(null);
            if (livestock != null) {
                farmId = livestock.farmId();
            }
        }

        // 1. Update device runtime status snapshot.
        // MANUAL_IMPORT backfills historical rows: it must not rewrite the
        // device's live snapshot (battery/rssi/lastOnlineAt) with stale values.
        if (source != TelemetrySource.MANUAL_IMPORT) {
            updateDeviceRuntimeStatus(device, readings);
            deviceRepository.save(device);
        }

       // 2. Derive segment distance before the current GPS fix becomes the latest row.
       deriveGpsDistance(device, readings, effectiveRecordedAt);

        // 3. Convert cumulative counters before the current row becomes the
        // previous baseline for these queries.
        computeStepDelta(device, readings, effectiveRecordedAt);
        computeGastricMotilityDelta(device, readings, effectiveRecordedAt, source);

        // 4. Write device operational timeseries
        logDeviceTelemetry(device, readings, effectiveRecordedAt, source);

        // 5. Enqueue GPS for GPS-capable devices; gps_logs is written by the outbox worker.
        enqueueGps(device, readings, effectiveRecordedAt, source);

        // 6. Keep device alerts aligned for the two live platform channels.
        if (source == TelemetrySource.AGENTIC_PLATFORM || source == TelemetrySource.THINGSBOARD) {
            detectDeviceAlerts(device, farmId, readings);
        }

        // 7. Publish telemetry event for cross-context consumption
        TelemetryReceivedEvent event = new TelemetryReceivedEvent(
                device.getId(), livestockId, farmId,
                device.getDeviceType(), readings, effectiveRecordedAt,
                source != null ? source.name() : "UNKNOWN");
        eventPublisher.publishEvent(event);

        // 8. Advance sync cursor to the ingested reportTime (not Instant.now()).
        // The cursor and reportTime must share the same time basis so the
        // > cursor filter in syncDevice() correctly skips already-processed
        // records. Using Instant.now() here created an 8-hour gap when the
        // platform reportTime is a local (UTC+8) value stored as UTC, causing
        // every dispatch to re-ingest the same records.
        if (source == TelemetrySource.AGENTIC_PLATFORM) {
            device.setLastTelemetrySyncedAt(effectiveRecordedAt);
            deviceRepository.save(device);
        }

        log.debug("Ingested telemetry for device [{}], source [{}], type [{}]",
                deviceId, source, device.getDeviceType());
    }

    /**
     * Backward-compatible ingest without source (defaults to HTTP).
     */
    @Transactional
    public void ingest(Long deviceId, Map<String, Object> readings, Instant recordedAt) {
        ingest(deviceId, readings, recordedAt, TelemetrySource.HTTP);
    }

   // --- Splitter methods ---

    /**
     * Compute stepNumber delta: platform reports cumulative value, activity_logs needs per-cycle increment.
     * Injects result as "stepCount" into readings for downstream HealthApplicationService consumption.
     * Three cases: first report (skip), normal delta (inject), regression/reset (discard).
     */
    private void computeStepDelta(Device device, Map<String, Object> readings, Instant recordedAt) {
        Integer currentStep = getInteger(readings, "stepNumber");
        if (currentStep == null) return;

        Integer lastStep = deviceTelemetryLogRepository
                .findLatestStepNumberByDeviceIdAndReportTimeBefore(device.getId(), recordedAt)
                .map(DeviceTelemetryLog::getStepNumber)
                .orElse(null);

        if (lastStep == null) {
            // First report: baseline only, no delta to inject
            return;
        }

        if (currentStep > lastStep) {
            int delta = currentStep - lastStep;
            readings.put("stepCount", delta);
        } else {
            // Regression or reset: discard this cycle
            log.warn("stepNumber regression: last={}, current={}, device={}", lastStep, currentStep, device.getId());
        }
    }

    /**
     * Capsule firmware reports a cumulative gastric motility counter. Health
     * consumers need the positive per-report delta; counter resets are ignored.
     */
    private void computeGastricMotilityDelta(
            Device device, Map<String, Object> readings, Instant recordedAt,
            TelemetrySource source) {
        if (device.getDeviceType() != DeviceType.CAPSULE || source == TelemetrySource.DATAGEN) {
            return;
        }
        Long currentCounter = getLong(readings, "gastricMotility");
        if (currentCounter == null) {
            return;
        }
        Long lastCounter = deviceTelemetryLogRepository
                .findLatestGastricMotilityByDeviceIdAndReportTimeBefore(device.getId(), recordedAt)
                .map(DeviceTelemetryLog::getGastricMotility)
                .orElse(null);
        if (lastCounter != null && currentCounter > lastCounter) {
            readings.put("gastricMotilityDelta", currentCounter - lastCounter);
        }
    }

    private void deriveGpsDistance(Device device, Map<String, Object> readings, Instant recordedAt) {
        if (!device.getDeviceType().supportsGps() || readings.containsKey("distanceMeters")) {
            return;
        }

        BigDecimal latitude = toBigDecimal(readings.get("latitude"));
        BigDecimal longitude = toBigDecimal(readings.get("longitude"));
        if (latitude == null || longitude == null
                || (latitude.compareTo(BigDecimal.ZERO) == 0
                    && longitude.compareTo(BigDecimal.ZERO) == 0)) {
            return;
        }

        DeviceTelemetryLog previous = deviceTelemetryLogRepository
                .findLatestGpsByDeviceIdAndReportTimeBefore(device.getId(), recordedAt)
                .orElse(null);
        var previousPoint = previous == null ? null : new GpsDistanceDerivationService.GpsSegmentPoint(
                previous.getLatitude(), previous.getLongitude(), previous.getReportTime());
        var currentPoint = new GpsDistanceDerivationService.GpsSegmentPoint(
                latitude, longitude, recordedAt);

        gpsDistanceDerivationService.deriveDistanceMeters(previousPoint, currentPoint)
                .ifPresent(distance -> readings.put("distanceMeters", distance));
    }

    private void updateDeviceRuntimeStatus(Device device, Map<String, Object> readings) {
        // runtimeStatus (online/offline) is now sourced from blade platform onlineStatus;
        // no longer derived locally from telemetry readings.
        Object battery = readings.get("battery");
        if (battery != null) device.setBatteryLevel(toInteger(battery));

        Object rssi = readings.get("rssi");
        if (rssi != null) device.setRssi(toInteger(rssi));

        Object snr = readings.get("snr");
        if (snr != null) device.setSnr(toBigDecimal(snr));

        Object gateway = readings.get("gatewayId");
        if (gateway != null) device.setLastGateway(gateway.toString());

        Object antiDis = readings.get("antiDisassemblyStatus");
        if (antiDis != null) device.setAntiDisassemblyStatus(toInteger(antiDis));

        device.setLastOnlineAt(Instant.now());
    }

    /**
     * @deprecated runtimeStatus is now sourced from the agentic-middle-platform
     * {@code onlineStatus} (1=online, otherwise offline). This local derivation
     * (including the {@code low_battery} value) is retained for reference only and
     * is no longer invoked by {@link #ingest}.
     */
    @Deprecated
    private String computeRuntimeStatus(Device device, Map<String, Object> readings) {
        Object antiDis = readings.get("antiDisassemblyStatus");
        if (antiDis != null && toInteger(antiDis) != 0) return "offline";
        Object battery = readings.get("battery");
        if (battery != null && toInteger(battery) < 10) return "low_battery";
        return "online";
    }

    private void logDeviceTelemetry(Device device, Map<String, Object> readings, Instant recordedAt,
                                    TelemetrySource source) {
        DeviceTelemetryLog logEntry = new DeviceTelemetryLog();
        logEntry.setDeviceId(device.getId());
        logEntry.setTenantId(device.getTenantId());
        // readings-first, snapshot fallback: MANUAL_IMPORT rows carry per-row
        // historical values (their device snapshot is intentionally untouched);
        // live sources already merged readings into the snapshot, so this is
        // behavior-neutral for AGENTIC_PLATFORM/DATAGEN/HTTP.
        Integer battery = getInteger(readings, "battery");
        logEntry.setBatteryLevel(battery != null ? battery : device.getBatteryLevel());
        Integer rssi = getInteger(readings, "rssi");
        logEntry.setRssi(rssi != null ? rssi : device.getRssi());
        BigDecimal snr = getBigDecimal(readings, "snr");
        logEntry.setSnr(snr != null ? snr : device.getSnr());
        String gatewayId = getString(readings, "gatewayId");
        logEntry.setGatewayId(gatewayId != null ? gatewayId : device.getLastGateway());
        logEntry.setLatitude(getBigDecimal(readings, "latitude"));
        logEntry.setLongitude(getBigDecimal(readings, "longitude"));
        logEntry.setStepNumber(getInteger(readings, "stepNumber"));
        logEntry.setGastricMotility(getLong(readings, "gastricMotility"));
        logEntry.setAccelXRaw(getInteger(readings, "accelXRaw"));
        logEntry.setAccelYRaw(getInteger(readings, "accelYRaw"));
        logEntry.setAccelZRaw(getInteger(readings, "accelZRaw"));
        logEntry.setAccelXG(getBigDecimal(readings, "accelXG"));
        logEntry.setAccelYG(getBigDecimal(readings, "accelYG"));
        logEntry.setAccelZG(getBigDecimal(readings, "accelZG"));
        logEntry.setAccelMagnitudeG(getBigDecimal(readings, "accelMagnitudeG"));
        logEntry.setMotionIntensity(getBigDecimal(readings, "motionIntensity"));
        logEntry.setActivityClass(getString(readings, "activityClass"));
        logEntry.setRollDegrees(getBigDecimal(readings, "rollDegrees"));
        logEntry.setPitchDegrees(getBigDecimal(readings, "pitchDegrees"));
        logEntry.setSource(source);
        logEntry.setReportTime(recordedAt);
        deviceTelemetryLogRepository.save(logEntry);
    }

   private void enqueueGps(Device device, Map<String, Object> readings, Instant recordedAt,
                           TelemetrySource source) {
       if (!device.getDeviceType().supportsGps()) return;

       Object latObj = readings.get("latitude");
       Object lngObj = readings.get("longitude");
       if (latObj != null && lngObj != null) {
           BigDecimal latitude;
           BigDecimal longitude;
           try {
               latitude = toBigDecimal(latObj);
               longitude = toBigDecimal(lngObj);
           } catch (RuntimeException e) {
               log.warn("Skipping unparseable GPS for device [{}]: {}", device.getId(), e.getMessage());
               return;
           }
           if (latitude == null || longitude == null
                   || latitude.abs().compareTo(BigDecimal.valueOf(90)) > 0
                   || longitude.abs().compareTo(BigDecimal.valueOf(180)) > 0) {
               log.warn("Skipping out-of-range GPS for device [{}]: lat={}, lng={}",
                       device.getId(), latObj, lngObj);
               return;
           }
           // Skip invalid GPS fixes (0,0 means no fix)
           if (latitude.compareTo(BigDecimal.ZERO) == 0
                   && longitude.compareTo(BigDecimal.ZERO) == 0) {
               log.debug("Skipping invalid GPS (0,0) for device [{}]", device.getId());
               return;
           }
           GpsIngestionTask task = new GpsIngestionTask();
           task.setDeviceId(device.getId());
           task.setLatitude(latitude);
           task.setLongitude(longitude);
           task.setRecordedAt(recordedAt);
           task.setSource(source);
           gpsIngestionTaskRepository.enqueue(task);
       }
   }

    private void detectDeviceAlerts(Device device, Long farmId, Map<String, Object> readings) {
        Object antiDis = readings.get("antiDisassemblyStatus");
        if (antiDis != null && toInteger(antiDis) != 0) {
            createDeviceAlertIfNotExists(device, farmId, AlertType.DEVICE_TAMPER, Severity.CRITICAL,
                    "设备防拆卸告警: " + device.getDeviceCode(),
                    "alert.device.tamper", List.of(device.getDeviceCode()));
        }
        if (device.getBatteryLevel() != null && device.getBatteryLevel() < 20) {
            createDeviceAlertIfNotExists(device, farmId, AlertType.DEVICE_LOW_BATTERY, Severity.WARNING,
                    "设备低电量: " + device.getBatteryLevel() + "%",
                    "alert.device.lowBattery", List.of(device.getBatteryLevel()));
        }
    }

    private void createDeviceAlertIfNotExists(Device device, Long farmId,
                                               AlertType type, Severity severity, String message,
                                               String messageKey, List<?> messageArgs) {
        List<Alert> existing = alertRepository.findByDeviceIdAndTypeAndStatus(
                device.getId(), type, AlertStatus.ACTIVE);
        if (!existing.isEmpty()) return;

        Alert alert = new Alert(farmId, null, null, device.getId(), type, severity, message);
        alert.setMessageKey(messageKey);
        alert.setMessageArgs(toJson(messageArgs));
        alertRepository.save(alert);
    }

    private String toJson(List<?> args) {
        try {
            return objectMapper.writeValueAsString(args);
        } catch (Exception e) {
            return "[]";
        }
    }

    // --- Type conversion helpers ---

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof BigDecimal bd) return bd;
        if (value instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return new BigDecimal(value.toString());
    }

    private Integer toInteger(Object value) {
        if (value == null) return null;
        if (value instanceof Integer i) return i;
        if (value instanceof Number n) return n.intValue();
        return Integer.parseInt(value.toString());
    }

    private Integer getInteger(Map<String, Object> readings, String key) {
        Object val = readings.get(key);
        if (val == null) return null;
        if (val instanceof Integer i) return i;
        if (val instanceof Number n) return n.intValue();
        return Integer.parseInt(val.toString());
    }

    private Long getLong(Map<String, Object> readings, String key) {
        Object val = readings.get(key);
        if (val == null) return null;
        if (val instanceof Long l) return l;
        if (val instanceof Number n) return n.longValue();
        return Long.parseLong(val.toString());
    }

    private BigDecimal getBigDecimal(Map<String, Object> readings, String key) {
        Object val = readings.get(key);
        if (val == null) return null;
        if (val instanceof BigDecimal bd) return bd;
        if (val instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return new BigDecimal(val.toString());
    }

    private String getString(Map<String, Object> readings, String key) {
        Object val = readings.get(key);
        return val != null ? val.toString() : null;
    }
}
