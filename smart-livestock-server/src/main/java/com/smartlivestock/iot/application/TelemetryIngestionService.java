package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.event.TelemetryReceivedEvent;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
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
 *   <li>Extracts GPS for TRACKER devices (gps_logs)</li>
 *   <li>Detects device alerts (tamper / low battery) — only for AGENTIC_PLATFORM source</li>
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
    private final GpsLogApplicationService gpsLogApplicationService;
    private final AlertRepository alertRepository;
    private final ApplicationEventPublisher eventPublisher;

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

        // 1. Update device runtime status snapshot
        updateDeviceRuntimeStatus(device, readings);
        deviceRepository.save(device);

        // 2. Write device operational timeseries
        logDeviceTelemetry(device, readings, effectiveRecordedAt);

        // 3. Extract GPS for TRACKER devices
        extractAndLogGps(device, readings, effectiveRecordedAt);

        // 4. Detect device alerts (only for AGENTIC_PLATFORM source)
        if (source == TelemetrySource.AGENTIC_PLATFORM) {
            detectDeviceAlerts(device, farmId, readings);
        }

        // 5. Publish telemetry event for cross-context consumption
        TelemetryReceivedEvent event = new TelemetryReceivedEvent(
                device.getId(), livestockId, farmId,
                device.getDeviceType(), readings, effectiveRecordedAt);
        eventPublisher.publishEvent(event);

        // 6. Advance sync cursor (only for AGENTIC_PLATFORM source)
        if (source == TelemetrySource.AGENTIC_PLATFORM) {
            device.setLastTelemetrySyncedAt(Instant.now());
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

    private void updateDeviceRuntimeStatus(Device device, Map<String, Object> readings) {
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

    private void logDeviceTelemetry(Device device, Map<String, Object> readings, Instant recordedAt) {
        DeviceTelemetryLog logEntry = new DeviceTelemetryLog();
        logEntry.setDeviceId(device.getId());
        logEntry.setTenantId(device.getTenantId());
        logEntry.setBatteryLevel(device.getBatteryLevel());
        logEntry.setRssi(device.getRssi());
        logEntry.setSnr(device.getSnr());
        logEntry.setGatewayId(device.getLastGateway());
        logEntry.setStepNumber(getInteger(readings, "stepNumber"));
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
        logEntry.setReportTime(recordedAt);
        deviceTelemetryLogRepository.save(logEntry);
    }

    private void extractAndLogGps(Device device, Map<String, Object> readings, Instant recordedAt) {
        if (device.getDeviceType() != com.smartlivestock.iot.domain.model.DeviceType.TRACKER) return;

        Object latObj = readings.get("latitude");
        Object lngObj = readings.get("longitude");
        if (latObj != null && lngObj != null) {
            BigDecimal latitude = toBigDecimal(latObj);
            BigDecimal longitude = toBigDecimal(lngObj);
            gpsLogApplicationService.logGps(device.getId(), latitude, longitude, null, recordedAt);
        }
    }

    private void detectDeviceAlerts(Device device, Long farmId, Map<String, Object> readings) {
        Object antiDis = readings.get("antiDisassemblyStatus");
        if (antiDis != null && toInteger(antiDis) != 0) {
            createDeviceAlertIfNotExists(device, farmId, AlertType.DEVICE_TAMPER, Severity.CRITICAL,
                    "设备防拆卸告警: " + device.getDeviceCode());
        }
        if (device.getBatteryLevel() != null && device.getBatteryLevel() < 20) {
            createDeviceAlertIfNotExists(device, farmId, AlertType.DEVICE_LOW_BATTERY, Severity.WARNING,
                    "设备低电量: " + device.getBatteryLevel() + "%");
        }
    }

    private void createDeviceAlertIfNotExists(Device device, Long farmId,
                                               AlertType type, Severity severity, String message) {
        List<Alert> existing = alertRepository.findByDeviceIdAndTypeAndStatus(
                device.getId(), type, AlertStatus.ACTIVE);
        if (!existing.isEmpty()) return;

        Alert alert = new Alert(farmId, null, null, device.getId(), type, severity, message);
        alertRepository.save(alert);
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
