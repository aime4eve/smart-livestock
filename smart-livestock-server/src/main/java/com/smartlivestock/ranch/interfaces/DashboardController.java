package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.LivestockApplicationService;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.application.dto.LivestockDto;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}")
@RequiredArgsConstructor
public class DashboardController {

    private final LivestockApplicationService livestockApplicationService;
    private final AlertApplicationService alertApplicationService;
    private final FenceApplicationService fenceApplicationService;
    private final IoTQueryPort ioTQueryPort;
    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;

    @GetMapping({"/dashboard", "/dashboard/summary"})
    public ResponseEntity<ApiResponse<Map<String, Object>>> summary(
            @PathVariable Long farmId) {
        List<LivestockDto> livestock = livestockApplicationService.listByFarm(farmId);
        List<AlertDto> alerts = alertApplicationService.listByFarm(farmId);
        List<FenceDto> fences = fenceApplicationService.listByFarm(farmId);

        long healthyCount = livestock.stream()
                .filter(l -> "HEALTHY".equals(l.healthStatus())).count();
        long warningCount = livestock.stream()
                .filter(l -> "WARNING".equals(l.healthStatus())).count();
        long criticalCount = livestock.stream()
                .filter(l -> "CRITICAL".equals(l.healthStatus())).count();
        long activeAlertCount = alerts.stream()
                .filter(a -> "ACTIVE".equals(a.status())).count();

        long onlineDeviceCount = ioTQueryPort.getDeviceStats(null).activeCount();

        // InFenceRate: livestock inside any active fence / livestock with GPS
        Double inFenceRate = calculateInFenceRate(farmId);

        // Alert summaries grouped by type (ACTIVE only)
        Map<String, Integer> fenceAlertSummary = buildFenceAlertSummary(alerts);
        Map<String, Integer> healthAlertSummary = buildHealthAlertSummary(alerts);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("livestockCount", livestock.size());
        data.put("onlineDeviceCount", onlineDeviceCount);
        data.put("activeAlertCount", activeAlertCount);
        data.put("fenceCount", fences.size());
        data.put("inFenceRate", inFenceRate);
        data.put("fenceAlertSummary", fenceAlertSummary);
        data.put("healthAlertSummary", healthAlertSummary);
        data.put("healthSummary", Map.of(
                "healthy", healthyCount,
                "warning", warningCount,
                "critical", criticalCount
        ));

        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    private Double calculateInFenceRate(Long farmId) {
        List<Livestock> livestockList = livestockRepository.findByFarmId(farmId);
        List<Fence> activeFences = fenceRepository.findByFarmId(farmId).stream()
                .filter(Fence::isActive).toList();

        if (livestockList.isEmpty()) return null; // no livestock = N/A
        if (activeFences.isEmpty()) return 1.0; // no fences = all "inside"

        long withGps = livestockList.stream()
                .filter(l -> l.getLastLatitude() != null && l.getLastLongitude() != null)
                .count();
        if (withGps == 0) return null; // no GPS data = N/A

        long inFence = livestockList.stream()
                .filter(l -> l.getLastLatitude() != null && l.getLastLongitude() != null)
                .filter(l -> {
                    GpsCoordinate pos = new GpsCoordinate(l.getLastLatitude(), l.getLastLongitude());
                    return activeFences.stream().anyMatch(f -> f.contains(pos));
                })
                .count();

        return (double) inFence / withGps;
    }

    private Map<String, Integer> buildFenceAlertSummary(List<AlertDto> alerts) {
        Map<String, Integer> summary = new LinkedHashMap<>();
        summary.put("FENCE_BREACH", 0);
        summary.put("FENCE_APPROACH", 0);
        summary.put("ZONE_APPROACH", 0);
        for (AlertDto alert : alerts) {
            if (!"ACTIVE".equals(alert.status())) continue;
            if (summary.containsKey(alert.type())) {
                summary.merge(alert.type(), 1, Integer::sum);
            }
        }
        return summary;
    }

    private Map<String, Integer> buildHealthAlertSummary(List<AlertDto> alerts) {
        Map<String, Integer> summary = new LinkedHashMap<>();
        summary.put("TEMPERATURE_ABNORMAL", 0);
        summary.put("DIGESTIVE_ABNORMAL", 0);
        summary.put("ESTRUS", 0);
        summary.put("EPIDEMIC", 0);
        for (AlertDto alert : alerts) {
            if (!"ACTIVE".equals(alert.status())) continue;
            if (summary.containsKey(alert.type())) {
                summary.merge(alert.type(), 1, Integer::sum);
            }
        }
        return summary;
    }
}
