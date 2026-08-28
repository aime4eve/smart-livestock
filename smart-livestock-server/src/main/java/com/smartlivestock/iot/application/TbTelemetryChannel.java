package com.smartlivestock.iot.application;

import com.fasterxml.jackson.databind.JsonNode;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbClient;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
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

    private final TbProperties properties;
    private final TbClient tbClient;
    private final TbDeviceBindingRepository bindingRepository;
    private final DeviceRepository deviceRepository;
    private final TelemetryIngestionService ingestionService;

    @Scheduled(fixedDelayString = "${smartlivestock.tb.poll-interval-ms:300000}")
    public void poll() {
        List<TbDeviceBinding> bindings = bindingRepository.findByStatus(TbDeviceBinding.Status.RESOLVED);
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
        long pageStart = binding.getTelemetryCursorMs() != null
                ? binding.getTelemetryCursorMs() + 1
                : now - properties.getLookbackDays() * 86_400_000L;
        long overallMaxTs = Long.MIN_VALUE;
        int pages = 0;

        while (pages < MAX_PAGES_PER_CYCLE) {
            JsonNode timeseries = tbClient.fetchTimeseries(
                    binding.getExternalDeviceId(), pageStart, now, properties.getBatchSize());
            List<TbTelemetryFrameParser.Frame> frames =
                    TbTelemetryFrameParser.extractFrames(timeseries, device.getDeviceType());
            if (frames.isEmpty()) break;

            long batchMaxTs = Long.MIN_VALUE;
            for (TbTelemetryFrameParser.Frame frame : frames) {
                // Continuation pages re-fetch the boundary frame (startTs is
                // inclusive); skip already-ingested frames.
                if (pages > 0 && frame.ts() <= pageStart) continue;
                ingestFrame(binding, device, frame);
                batchMaxTs = Math.max(batchMaxTs, frame.ts());
            }
            if (batchMaxTs == Long.MIN_VALUE) break;
            overallMaxTs = Math.max(overallMaxTs, batchMaxTs);
            pages++;
            if (frames.size() < properties.getBatchSize() || batchMaxTs == Long.MIN_VALUE) break;
            // Limit truncation: continue from the boundary frame onward.
            pageStart = batchMaxTs;
        }

        if (overallMaxTs != Long.MIN_VALUE) {
            binding.setTelemetryCursorMs(overallMaxTs);
            binding.setLastEventAt(Instant.ofEpochMilli(overallMaxTs));
            bindingRepository.save(binding);
            log.info("[TB] device {} cursor advanced to {}", device.getId(), overallMaxTs);
        }
    }

    private void ingestFrame(TbDeviceBinding binding, Device device,
                             TbTelemetryFrameParser.Frame frame) {
        Map<String, Object> readings = new java.util.HashMap<>(frame.readings());
        clampGps(readings, device.getId());
        if (device.getDeviceType() == com.smartlivestock.iot.domain.model.DeviceType.TRACKER) {
            com.smartlivestock.iot.application.AgenticPlatformReportData
                    .applyAccelerometerConversion(readings);
        }
        try {
            ingestionService.ingest(device.getId(), readings,
                    Instant.ofEpochMilli(frame.ts()), TelemetrySource.THINGSBOARD);
        } catch (Exception e) {
            // Per-frame fail-open: one bad frame (e.g. STATE_CONFLICT on a
            // deactivated device) must not abort the remaining frames.
            log.warn("[TB] device {} frame {} ingest failed: {}", device.getId(), frame.ts(), e.getMessage());
        }
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
