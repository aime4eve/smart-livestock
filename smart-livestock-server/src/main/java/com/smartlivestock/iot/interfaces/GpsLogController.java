package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.GpsLogApplicationService;
import com.smartlivestock.iot.application.InstallationApplicationService;
import com.smartlivestock.iot.application.dto.GpsLogDto;
import com.smartlivestock.iot.application.dto.InstallationDto;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/farms/{farmId}")
@RequiredArgsConstructor
public class GpsLogController {

    private final GpsLogApplicationService gpsLogApplicationService;
    private final InstallationApplicationService installationApplicationService;

    /**
     * GET /api/v1/farms/{farmId}/gps-logs/latest
     * Get latest GPS coordinates for all tracked livestock in a farm.
     */
    @GetMapping("/gps-logs/latest")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLatestGps(
            @PathVariable Long farmId) {
        // Cross-context: get active installations → latest GPS per device
        List<GpsLogDto> latestLogs = installationApplicationService.findAllActive().stream()
                .map(inst -> gpsLogApplicationService.getByDevice(inst.deviceId()).stream()
                        .reduce((first, second) -> second) // last = latest
                        .orElse(null))
                .filter(Objects::nonNull)
                .collect(Collectors.toList());

        Map<String, Object> data = Map.of("items", latestLogs);
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/farms/{farmId}/livestock/{livestockId}/gps-logs
     * Get GPS history for a specific livestock.
     * Path: livestock -> installation -> device -> gps_logs
     */
    @GetMapping("/livestock/{livestockId}/gps-logs")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLivestockGpsHistory(
            @PathVariable Long farmId,
            @PathVariable Long livestockId,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "100") int pageSize,
            @RequestParam(required = false) Integer sampleSize) {
        // Cross-context: livestock → active installation → device → GPS logs
        return installationApplicationService.getActiveInstallationByLivestock(livestockId)
                .map(inst -> {
                    List<GpsLogDto> allLogs;
                   if (startTime != null && endTime != null && sampleSize != null && sampleSize > 0) {
                       allLogs = gpsLogApplicationService.sampleByDeviceAndTimeRange(
                               inst.deviceId(),
                                parseInstant(startTime),
                                parseInstant(endTime),
                                sampleSize);
                    } else if (startTime != null && endTime != null) {
                       allLogs = gpsLogApplicationService.getByDeviceAndTimeRange(
                               inst.deviceId(),
                                parseInstant(startTime),
                                parseInstant(endTime));
                    } else {
                        allLogs = gpsLogApplicationService.getByDevice(inst.deviceId());
                    }
                    int total = allLogs.size();
                    // When sampling is requested, return all sampled points
                    // without further pagination — the sample IS the page.
                    if (sampleSize != null && sampleSize > 0) {
                        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                                "items", allLogs,
                                "total", total
                        )));
                    }
                    int from = Math.min((page - 1) * pageSize, total);
                    int to = Math.min(from + pageSize, total);

                    Map<String, Object> data = Map.of(
                            "items", allLogs.subList(from, to),
                            "page", page,
                            "pageSize", pageSize,
                            "total", total
                    );
                    return ResponseEntity.ok(ApiResponse.ok(data));
                })
                .orElseGet(() -> ResponseEntity.ok(ApiResponse.ok(Map.of(
                        "items", List.of(), "page", page, "pageSize", pageSize, "total", 0
                ))));
    }

    // Handle both "Z" suffix and "+00:00" offset formats; URL encoding
    // may turn "+" into a space, so normalize before parsing.
    private static Instant parseInstant(String value) {
        String normalized = value.trim().replace(" ", "+");
        return Instant.parse(normalized);
    }
}
