package com.smartlivestock.ranch.interfaces;

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
public class MapController {

    private final LivestockApplicationService livestockApplicationService;
    private final FenceApplicationService fenceApplicationService;
    private final AlertApplicationService alertApplicationService;

    @GetMapping({"/map", "/map/overview"})
    public ResponseEntity<ApiResponse<Map<String, Object>>> overview(
            @PathVariable Long farmId) {
        List<LivestockDto> livestock = livestockApplicationService.listByFarm(farmId);
        List<FenceDto> fences = fenceApplicationService.listByFarm(farmId);
        List<AlertDto> alerts = alertApplicationService.listByFarm(farmId);

        List<Map<String, Object>> livestockPositions = livestock.stream()
                .filter(l -> l.lastLatitude() != null && l.lastLongitude() != null)
                .map(l -> Map.<String, Object>of(
                        "id", l.id(),
                        "livestockCode", l.livestockCode() != null ? l.livestockCode() : "",
                        "lng", l.lastLongitude(),
                        "lat", l.lastLatitude(),
                        "healthStatus", l.healthStatus(),
                        "alertCount", 0
                ))
                .toList();

        Map<String, Object> data = Map.of(
                "livestock", livestockPositions,
                "fences", fences,
                "alerts", alerts
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }
}
