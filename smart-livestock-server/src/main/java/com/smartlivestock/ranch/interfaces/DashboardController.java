package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.LivestockApplicationService;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.application.dto.LivestockDto;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
                .filter(a -> "PENDING".equals(a.status()) || "ACKNOWLEDGED".equals(a.status())).count();

        // Phase 1: tenant-level ACTIVE device count (devices have no farm_id)
        long onlineDeviceCount = ioTQueryPort.getDeviceStats(null).activeCount();

        Map<String, Object> data = Map.of(
                "livestockCount", livestock.size(),
                "onlineDeviceCount", onlineDeviceCount,
                "activeAlertCount", activeAlertCount,
                "fenceCount", fences.size(),
                "healthSummary", Map.of(
                        "healthy", healthyCount,
                        "warning", warningCount,
                        "critical", criticalCount
                )
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }
}
