package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.TileAdminService;
import com.smartlivestock.ranch.application.dto.FarmTileStatusDto;
import com.smartlivestock.ranch.application.dto.TileGenerationTaskDto;
import com.smartlivestock.ranch.application.dto.TileRegionDto;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/tiles")
@RequiredArgsConstructor
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class TileAdminController {

    private final TileAdminService tileAdminService;

    @GetMapping("/regions")
    public ResponseEntity<ApiResponse<List<TileRegionDto>>> listRegions() {
        return ResponseEntity.ok(ApiResponse.ok(tileAdminService.listRegions()));
    }

    @PostMapping("/regions")
    public ResponseEntity<ApiResponse<TileRegionDto>> upsertRegion(@RequestBody Map<String, Object> body) {
        TileRegionDto dto = tileAdminService.upsertRegion(
                (String) body.get("name"),
                ((Number) body.get("minLon")).doubleValue(),
                ((Number) body.get("minLat")).doubleValue(),
                ((Number) body.get("maxLon")).doubleValue(),
                ((Number) body.get("maxLat")).doubleValue(),
                body.get("minZoom") != null ? ((Number) body.get("minZoom")).intValue() : 11,
                body.get("maxZoom") != null ? ((Number) body.get("maxZoom")).intValue() : 15,
                (String) body.get("fileName"),
                body.get("fileSize") != null ? ((Number) body.get("fileSize")).longValue() : null,
                (String) body.get("md5"),
                (String) body.get("status")
        );
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    @GetMapping("/tasks")
    public ResponseEntity<ApiResponse<List<TileGenerationTaskDto>>> listTasks(
            @RequestParam(required = false) String status) {
        return ResponseEntity.ok(ApiResponse.ok(tileAdminService.listTasks(status)));
    }

    @GetMapping("/tasks/{id}")
    public ResponseEntity<ApiResponse<TileGenerationTaskDto>> getTask(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(tileAdminService.getTask(id)));
    }

    @PostMapping("/tasks")
    public ResponseEntity<ApiResponse<TileGenerationTaskDto>> createTask(@RequestBody Map<String, Object> body) {
        TileGenerationTaskDto dto = tileAdminService.createTask(
                (String) body.get("regionName"),
                ((Number) body.get("minLon")).doubleValue(),
                ((Number) body.get("minLat")).doubleValue(),
                ((Number) body.get("maxLon")).doubleValue(),
                ((Number) body.get("maxLat")).doubleValue(),
                body.get("minZoom") != null ? ((Number) body.get("minZoom")).intValue() : 11,
                body.get("maxZoom") != null ? ((Number) body.get("maxZoom")).intValue() : 15,
                body.get("coverageRatio") != null ? ((Number) body.get("coverageRatio")).doubleValue() : null,
                body.get("isCustomRegion") != null && (boolean) body.get("isCustomRegion")
        );
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    @PutMapping("/tasks/{id}/status")
    public ResponseEntity<ApiResponse<TileGenerationTaskDto>> updateTaskStatus(
            @PathVariable Long id, @RequestBody Map<String, Object> body) {
        TileGenerationTaskDto dto = tileAdminService.updateTaskStatus(id,
                (String) body.get("status"),
                body.get("tileCount") != null ? ((Number) body.get("tileCount")).intValue() : null,
                body.get("fileSizeMb") != null ? ((Number) body.get("fileSizeMb")).doubleValue() : null,
                (String) body.get("errorMessage")
        );
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    @GetMapping("/farm-tasks")
    public ResponseEntity<ApiResponse<List<FarmTileStatusDto>>> listFarmTasks() {
        List<FarmTileStatusDto> allStatuses = tileAdminService.listFarmTileStatuses();
        return ResponseEntity.ok(ApiResponse.ok(allStatuses));
    }
}
