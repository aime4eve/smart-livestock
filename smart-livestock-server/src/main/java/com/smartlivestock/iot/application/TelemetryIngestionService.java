package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.event.TelemetryReceivedEvent;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

/**
 * IoT telemetry ingestion service.
 * Validates device identity and installation, resolves livestock/farm context
 * via ACL port (RanchQueryPort), extracts device ops and GPS data from readings,
 * then publishes a TelemetryReceivedEvent for cross-context consumption via RocketMQ.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TelemetryIngestionService {

    private final DeviceRepository deviceRepository;
    private final InstallationRepository installationRepository;
    private final RanchQueryPort ranchQueryPort;
    private final GpsLogApplicationService gpsLogApplicationService;
    private final ApplicationEventPublisher eventPublisher;

    /**
     * Ingest telemetry data from a device.
     *
     * @param deviceId   the device reporting telemetry
     * @param readings   map of sensor readings (generic, device-type agnostic)
     * @param recordedAt timestamp of the reading
     */
    @Transactional
    public void ingest(Long deviceId, Map<String, Object> readings, Instant recordedAt) {
        Instant effectiveRecordedAt = recordedAt != null ? recordedAt : Instant.now();

        // 1. Validate device exists and is ACTIVE
        Device device = deviceRepository.findById(deviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "设备不存在: " + deviceId));

        if (device.getStatus() != DeviceStatus.ACTIVE) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "设备未激活: " + device.getStatus());
        }

        // 2. Find active installation → livestockId
        Installation installation = installationRepository.findActiveByDeviceId(deviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "设备无活跃安装记录: " + deviceId));

        Long livestockId = installation.getLivestockId();

        // 3. Resolve farmId via ACL port (no cross-context repository import)
        LivestockInfo livestock = ranchQueryPort.findLivestockById(livestockId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "牲畜不存在: " + livestockId));

        Long farmId = livestock.farmId();

        // 4. Update device runtime status from telemetry (battery, voltage)
        updateDeviceRuntimeStatus(device, readings);

        // 5. Extract GPS from TRACKER readings → same-context GPS logging
        extractAndLogGps(device, readings, effectiveRecordedAt);

        // 6. Publish generic telemetry event (readings Map passthrough)
        TelemetryReceivedEvent event = new TelemetryReceivedEvent(
                device.getId(), livestockId, farmId,
                device.getDeviceType(), readings, effectiveRecordedAt);
        eventPublisher.publishEvent(event);

        log.debug("Published TelemetryReceivedEvent for device [{}], livestock [{}], type [{}]",
                deviceId, livestockId, device.getDeviceType());
    }

    private void updateDeviceRuntimeStatus(Device device, Map<String, Object> readings) {
        Object batteryLevel = readings.get("batteryLevel");
        Object batteryVoltage = readings.get("batteryVoltage");

        if (batteryLevel != null) {
            device.setBatteryLevel(toInteger(batteryLevel));
        }
        // batteryVoltage can be stored later when Device model supports it
    }

    private void extractAndLogGps(Device device, Map<String, Object> readings, Instant recordedAt) {
        if (device.getDeviceType() != com.smartlivestock.iot.domain.model.DeviceType.TRACKER) {
            return;
        }

        Object latObj = readings.get("latitude");
        Object lngObj = readings.get("longitude");

        if (latObj != null && lngObj != null) {
            BigDecimal latitude = toBigDecimal(latObj);
            BigDecimal longitude = toBigDecimal(lngObj);
            gpsLogApplicationService.logGps(device.getId(), latitude, longitude, null, recordedAt);
        }
    }

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
}
