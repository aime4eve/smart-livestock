package com.smartlivestock.iot.application;

import com.fasterxml.jackson.databind.JsonNode;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbClient;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * ThingsBoard REST telemetry channel (NIX-179 Phase 1).
 * Pulls bound devices' timeseries with a per-device persistent cursor and
 * feeds frames through the unified ingest() entry. Fail-open: any error on
 * one device never blocks other devices or the blade channel.
 */
@Component
@ConditionalOnProperty(name = "smartlivestock.tb.enabled", havingValue = "true")
@RequiredArgsConstructor
@Slf4j
public class TbTelemetryChannel {

    private static final int MAX_PAGES_PER_CYCLE = 50;

    public enum TriggerResult { TRIGGERED, BINDING_NOT_FOUND, TRIGGER_FAILED }

    private final TbProperties properties;
    private final TbClient tbClient;
    private final TbDeviceBindingRepository bindingRepository;
    private final DeviceRepository deviceRepository;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final TelemetryIngestionService ingestionService;

    @Scheduled(fixedDelayString = "${smartlivestock.tb.poll-interval-ms:300000}")
    public void poll() {
        if (properties.getTenantId() == null || properties.getTenantId() <= 0) {
            log.error("[TB] invalid tenant-id {}, skip cycle", properties.getTenantId());
            return;
        }
        List<TbDeviceBinding> bindings = bindingRepository.findByTenantIdAndStatus(
                properties.getTenantId(), TbDeviceBinding.Status.RESOLVED);
        if (bindings.isEmpty()) return;
        log.info("[TB] polling {} bound device(s)", bindings.size());
        for (TbDeviceBinding binding : bindings) {
            try {
                processBinding(binding);
            } catch (Exception e) {
                log.warn("[TB] device {} (eui={}) cycle failed: {}",
                        binding.getDeviceId(), binding.getDeviceEui(), e.getMessage());
            }
        }
    }

    public TriggerResult pollDevice(Long deviceId) {
        List<TbDeviceBinding> bindings = bindingRepository.findByTenantIdAndStatus(
                properties.getTenantId(), TbDeviceBinding.Status.RESOLVED);
        TbDeviceBinding binding = bindings.stream()
                .filter(item -> deviceId.equals(item.getDeviceId()))
                .findFirst().orElse(null);
        if (binding == null) return TriggerResult.BINDING_NOT_FOUND;
        try {
            processBinding(binding);
            return TriggerResult.TRIGGERED;
        } catch (Exception e) {
            log.warn("[TB] immediate pull for device {} failed: {}", deviceId, e.getMessage());
            return TriggerResult.TRIGGER_FAILED;
        }
    }

    private void processBinding(TbDeviceBinding binding) {
        Device device = deviceRepository.findById(binding.getDeviceId()).orElse(null);
        if (device == null) {
            log.warn("[TB] bound device {} missing locally, skipping", binding.getDeviceId());
            return;
        }
        if (device.getStatus() != DeviceStatus.ACTIVE) {
            log.debug("[TB] device {} not ACTIVE ({}), skipping", device.getId(), device.getStatus());
            return;
        }

        long now = System.currentTimeMillis();
        binding.setLastPollAt(Instant.ofEpochMilli(now));
        long pageStart = binding.getTelemetryCursorMs() != null
                ? binding.getTelemetryCursorMs() + 1
                : now - properties.getLookbackDays() * 86_400_000L;
        long overallMaxTs = Long.MIN_VALUE;
        long skippedMaxTs = Long.MIN_VALUE;
        int pages = 0;
        boolean failed = false;

        while (pages < MAX_PAGES_PER_CYCLE) {
            List<TbTelemetryFrameParser.Frame> frames;
            try {
                JsonNode timeseries = tbClient.fetchTimeseries(
                        binding.getExternalDeviceId(), pageStart, now, properties.getBatchSize());
                TbTelemetryFrameParser.ParseResult parsed =
                        TbTelemetryFrameParser.extract(timeseries, device.getDeviceType());
                frames = parsed.frames();
                // Undecodable frames (e.g. a modified TB rule chain saving
                // decodeStatus:false results) are dropped on purpose; the
                // cursor must pass them or the same page is re-fetched forever.
                if (!parsed.skippedTs().isEmpty()) {
                    skippedMaxTs = Math.max(skippedMaxTs,
                            parsed.skippedTs().get(parsed.skippedTs().size() - 1));
                    log.warn("[TB] device {} skipping {} undecodable frame(s), latest at {}",
                            device.getId(), parsed.skippedTs().size(),
                            parsed.skippedTs().get(parsed.skippedTs().size() - 1));
                }
            } catch (Exception e) {
                log.warn("[TB] device {} page failed at {}: {}",
                        device.getId(), pageStart, e.getMessage());
                failed = true;
                break;
            }
            if (frames.isEmpty()) break;

            long batchMaxTs = Long.MIN_VALUE;
            for (TbTelemetryFrameParser.Frame frame : frames) {
                // Continuation pages re-fetch the boundary frame (startTs is
                // inclusive); skip already-ingested frames.
                if (pages > 0 && frame.ts() <= pageStart) continue;
                if (!ingestFrame(device, frame)) {
                    failed = true;
                    break;
                }
                batchMaxTs = Math.max(batchMaxTs, frame.ts());
            }
            pages++;
            overallMaxTs = Math.max(overallMaxTs, batchMaxTs);
            if (failed) break;
            if (batchMaxTs == Long.MIN_VALUE) break;
            if (frames.size() < properties.getBatchSize() || batchMaxTs == Long.MIN_VALUE) break;
            // Limit truncation: continue from the boundary frame onward.
            pageStart = batchMaxTs;
        }

        // Health is persisted even when nothing was ingested so the blade
        // dispatcher can degrade this device to the blade channel.
        if (failed) {
            binding.setConsecutiveFailures(binding.getConsecutiveFailures() + 1);
            // Keep the successful prefix cursor; never jump past a failed frame.
            if (overallMaxTs != Long.MIN_VALUE) {
                binding.setTelemetryCursorMs(overallMaxTs);
                binding.setLastEventAt(Instant.ofEpochMilli(overallMaxTs));
            }
        } else {
            binding.setConsecutiveFailures(0);
            long processedMaxTs = Math.max(overallMaxTs, skippedMaxTs);
            if (processedMaxTs != Long.MIN_VALUE) {
                binding.setTelemetryCursorMs(processedMaxTs);
                binding.setLastEventAt(Instant.ofEpochMilli(processedMaxTs));
                log.info("[TB] device {} cursor advanced to {}", device.getId(), processedMaxTs);
            }
        }
        bindingRepository.save(binding);
    }

    private boolean ingestFrame(Device device, TbTelemetryFrameParser.Frame frame) {
        Map<String, Object> readings = new java.util.HashMap<>(frame.readings());
        clampGps(readings, device.getId());
        if (device.getDeviceType() == com.smartlivestock.iot.domain.model.DeviceType.TRACKER) {
            com.smartlivestock.iot.application.AgenticPlatformReportData
                    .applyAccelerometerConversion(readings);
        }
        Instant recordedAt = Instant.ofEpochMilli(frame.ts());
        if (deviceTelemetryLogRepository.existsByDeviceIdAndReportTime(device.getId(), recordedAt)) {
            log.debug("[TB] device {} frame {} already ingested", device.getId(), frame.ts());
            return true;
        }
        try {
            ingestionService.ingest(device.getId(), readings, recordedAt, TelemetrySource.THINGSBOARD);
        } catch (Exception e) {
            if (e instanceof DataIntegrityViolationException
                    && deviceTelemetryLogRepository.existsByDeviceIdAndReportTime(device.getId(), recordedAt)) {
                log.info("[TB] device {} frame {} concurrently ingested", device.getId(), frame.ts());
                return true;
            }
            log.warn("[TB] device {} frame {} ingest failed: {}",
                    device.getId(), frame.ts(), e.getMessage());
            return false;
        }
        return true;
    }

    private void clampGps(Map<String, Object> readings, Long deviceId) {
        for (String key : List.of("latitude", "longitude")) {
            Object value = readings.get(key);
            if (value instanceof BigDecimal decimal
                    && decimal.abs().compareTo(BigDecimal.valueOf(1000)) >= 0) {
                log.warn("[TB] device {} has out-of-range {}={}, clamping", deviceId, key, decimal);
                readings.put(key, null);
            }
        }
    }
}
