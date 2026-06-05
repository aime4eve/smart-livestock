package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.TelemetryIngestionService;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * App API controller for IoT telemetry ingestion.
 * Separate from DeviceController to avoid route conflicts and maintain clear responsibility.
 *
 * POST /api/v1/farms/{farmId}/telemetry — device telemetry data ingestion
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/telemetry")
@RequiredArgsConstructor
public class TelemetryController {

    private final TelemetryIngestionService telemetryIngestionService;

    /**
     * POST /api/v1/farms/{farmId}/telemetry
     *
     * Request body:
     * {
     *   "deviceId": 51,
     *   "readings": [
     *     { "temperature": 38.6, "motilityFrequency": 3.2, "recordedAt": "2026-06-04T10:00:00Z" }
     *   ]
     * }
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> ingestTelemetry(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {

        Long deviceId = toLong(body.get("deviceId"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> readings = (List<Map<String, Object>>) body.get("readings");

        if (deviceId == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(ErrorCode.VALIDATION_ERROR,
                            "deviceId 不能为空"));
        }

        if (readings == null || readings.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(ErrorCode.VALIDATION_ERROR,
                            "readings 不能为空"));
        }

        int processed = 0;
        for (Map<String, Object> reading : readings) {
            Instant recordedAt = reading.containsKey("recordedAt")
                    ? Instant.parse((String) reading.get("recordedAt"))
                    : null;
            telemetryIngestionService.ingest(deviceId, reading, recordedAt);
            processed++;
        }

        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "deviceId", deviceId,
                "processed", processed
        )));
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Long l) return l;
        if (value instanceof Number n) return n.longValue();
        return Long.parseLong(value.toString());
    }
}
