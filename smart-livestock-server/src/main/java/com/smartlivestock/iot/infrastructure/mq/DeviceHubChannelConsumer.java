package com.smartlivestock.iot.infrastructure.mq;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.iot.application.AgenticPlatformReportData;
import com.smartlivestock.iot.application.TbTelemetryFrameParser;
import com.smartlivestock.iot.application.TelemetryIngestionService;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.ConsumeMode;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

/**
 * DeviceHub push channel: consumes normalized TelemetryFrame events from the
 * shared HKT-DeviceHub RocketMQ cluster (topic DEVICEHUB_TELEMETRY_FRAME,
 * tag LIVESTOCK) and feeds them through the unified ingest() entry, aligned
 * with the TB pull channel (TbTelemetryChannel) output.
 * <p>
 * DeviceHub provides at-least-once, unordered delivery (see
 * telemetry-event-contract.md). Idempotency relies on the
 * (device_id, report_time) unique key, same as the TB pull channel:
 * pre-checked via existsByDeviceIdAndReportTime and re-checked after a
 * DataIntegrityViolationException race. Unknown devices and undecodable
 * frames are logged + counted and swallowed (they are permanent gaps, not
 * poison messages); transient ingest failures propagate so RocketMQ retries.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "smartlivestock.devicehub.enabled", havingValue = "true")
@RocketMQMessageListener(
        nameServer = "${smartlivestock.devicehub.mq-name-server}",
        topic = "${smartlivestock.devicehub.mq-topic}",
        consumerGroup = "${smartlivestock.devicehub.mq-consumer-group}",
        selectorExpression = "LIVESTOCK",
        consumeThreadMax = 20,
        consumeMode = ConsumeMode.CONCURRENTLY
)
public class DeviceHubChannelConsumer implements RocketMQListener<String> {

    private static final int CONTRACT_VERSION = 1;

    private final ObjectMapper objectMapper;
    private final TbDeviceBindingRepository bindingRepository;
    private final DeviceRepository deviceRepository;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final TelemetryIngestionService ingestionService;

    private final AtomicLong ingestedCount = new AtomicLong();
    private final AtomicLong duplicateCount = new AtomicLong();
    private final AtomicLong unknownDeviceCount = new AtomicLong();
    private final AtomicLong undecodableCount = new AtomicLong();
    private final AtomicLong malformedCount = new AtomicLong();

    @Override
    public void onMessage(String message) {
        JsonNode frame;
        try {
            frame = objectMapper.readTree(message);
        } catch (Exception e) {
            log.warn("[DeviceHub] malformed frame dropped (total {}): {}",
                    malformedCount.incrementAndGet(), e.getMessage());
            return;
        }
        process(frame);
    }

    void process(JsonNode frame) {
        String frameId = frame.path("frameId").asText(null);
        String devEui = frame.path("devEui").asText(null);
        String tbDeviceId = frame.path("tbDeviceId").asText(null);
        long ts = frame.path("ts").asLong(0);
        if (frame.path("version").asInt(-1) != CONTRACT_VERSION
                || frameId == null || devEui == null || tbDeviceId == null || ts <= 0) {
            log.warn("[DeviceHub] frame with missing/invalid contract fields dropped (total {}): {}",
                    malformedCount.incrementAndGet(), frame);
            return;
        }

        TbDeviceBinding binding = bindingRepository
                .findByProviderAndExternalDeviceId(TbDeviceBinding.PROVIDER_THINGSBOARD, tbDeviceId)
                .orElseGet(() -> bindingRepository
                        .findByProviderAndDeviceEui(TbDeviceBinding.PROVIDER_THINGSBOARD, devEui)
                        .orElse(null));
        if (binding == null || binding.getStatus() != TbDeviceBinding.Status.RESOLVED) {
            log.warn("[DeviceHub] no RESOLVED binding for eui={} tbDeviceId={} frameId={} (total {})",
                    devEui, tbDeviceId, frameId, unknownDeviceCount.incrementAndGet());
            return;
        }
        Device device = deviceRepository.findById(binding.getDeviceId()).orElse(null);
        if (device == null) {
            log.warn("[DeviceHub] bound device {} missing locally, frame {} dropped (total {})",
                    binding.getDeviceId(), frameId, unknownDeviceCount.incrementAndGet());
            return;
        }
        if (device.getStatus() != DeviceStatus.ACTIVE) {
            log.debug("[DeviceHub] device {} not ACTIVE ({}), frame {} skipped",
                    device.getId(), device.getStatus(), frameId);
            return;
        }

        Map<String, Object> readings = TbTelemetryFrameParser.mapResultProperties(
                frame.path("properties"));
        if (readings.isEmpty() && frame.hasNonNull("dataHex")) {
            readings = TbTelemetryFrameParser.decodeDataHexFallback(
                    frame.path("dataHex").asText(), device.getDeviceType());
        }
        if (readings == null || readings.isEmpty()) {
            log.warn("[DeviceHub] undecodable frame {} for device {} dropped (total {})",
                    frameId, device.getId(), undecodableCount.incrementAndGet());
            return;
        }
        readings = new HashMap<>(readings);
        if (frame.hasNonNull("rssi")) readings.put("rssi", frame.path("rssi").asInt());
        if (frame.hasNonNull("snr")) readings.put("snr", frame.path("snr").asInt());
        if (frame.hasNonNull("gatewayId")) readings.put("gatewayId", frame.path("gatewayId").asText());
        clampGps(readings, device.getId());
        if (device.getDeviceType() == DeviceType.TRACKER) {
            AgenticPlatformReportData.applyAccelerometerConversion(readings);
        }

        Instant recordedAt = Instant.ofEpochMilli(ts);
        if (deviceTelemetryLogRepository.existsByDeviceIdAndReportTime(device.getId(), recordedAt)) {
            log.debug("[DeviceHub] device {} frame {} (ts={}) already ingested (total {})",
                    device.getId(), frameId, ts, duplicateCount.incrementAndGet());
            return;
        }
        try {
            ingestionService.ingest(device.getId(), readings, recordedAt, TelemetrySource.THINGSBOARD);
            ingestedCount.incrementAndGet();
            log.debug("[DeviceHub] device {} ingested frame {} at {}", device.getId(), frameId, recordedAt);
        } catch (DataIntegrityViolationException e) {
            // At-least-once delivery racing the pull channel or a retry: the
            // (device_id, report_time) unique key already holds the row.
            if (deviceTelemetryLogRepository.existsByDeviceIdAndReportTime(device.getId(), recordedAt)) {
                log.info("[DeviceHub] device {} frame {} concurrently ingested (total {})",
                        device.getId(), frameId, duplicateCount.incrementAndGet());
                return;
            }
            throw e;
        }
    }

    private void clampGps(Map<String, Object> readings, Long deviceId) {
        for (String key : List.of("latitude", "longitude")) {
            Object value = readings.get(key);
            if (value instanceof BigDecimal decimal
                    && decimal.abs().compareTo(BigDecimal.valueOf(1000)) >= 0) {
                log.warn("[DeviceHub] device {} has out-of-range {}={}, clamping", deviceId, key, decimal);
                readings.put(key, null);
            }
        }
    }

    public long getIngestedCount() {
        return ingestedCount.get();
    }

    public long getDuplicateCount() {
        return duplicateCount.get();
    }

    public long getUnknownDeviceCount() {
        return unknownDeviceCount.get();
    }

    public long getUndecodableCount() {
        return undecodableCount.get();
    }

    public long getMalformedCount() {
        return malformedCount.get();
    }
}
