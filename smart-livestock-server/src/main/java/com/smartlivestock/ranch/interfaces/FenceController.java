package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.command.CreateFenceCommand;
import com.smartlivestock.ranch.application.command.UpdateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/fences")
@RequiredArgsConstructor
public class FenceController {

    private final FenceApplicationService fenceApplicationService;

    /**
     * GET /api/v1/farms/{farmId}/fences
     * List fences for a farm.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listFences(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        List<FenceDto> fences = fenceApplicationService.listByFarm(farmId);
        Map<String, Object> data = Map.of(
                "items", fences,
                "page", page,
                "pageSize", pageSize,
                "total", fences.size()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/farms/{farmId}/fences
     * Create a new fence.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<FenceDto>> createFence(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        CreateFenceCommand command = new CreateFenceCommand(
                farmId,
                (String) body.get("name"),
                parseVertices(body.get("vertices")),
                (String) body.get("color")
        );
        FenceDto fence = fenceApplicationService.createFence(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(fence));
    }

    /**
     * GET /api/v1/farms/{farmId}/fences/{fenceId}
     * Get fence detail.
     */
    @GetMapping("/{fenceId}")
    public ResponseEntity<ApiResponse<FenceDto>> getFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId) {
        FenceDto fence = fenceApplicationService.getFence(fenceId);
        return ResponseEntity.ok(ApiResponse.ok(fence));
    }

    /**
     * PUT /api/v1/farms/{farmId}/fences/{fenceId}
     * Update fence info.
     */
    @PutMapping("/{fenceId}")
    public ResponseEntity<ApiResponse<FenceDto>> updateFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId,
            @RequestBody Map<String, Object> body) {
        UpdateFenceCommand command = new UpdateFenceCommand(
                (String) body.get("name"),
                parseVertices(body.get("vertices")),
                (String) body.get("color")
        );
        FenceDto fence = fenceApplicationService.updateFence(fenceId, command);
        return ResponseEntity.ok(ApiResponse.ok(fence));
    }

    /**
     * DELETE /api/v1/farms/{farmId}/fences/{fenceId}
     * Delete a fence.
     */
    @DeleteMapping("/{fenceId}")
    public ResponseEntity<ApiResponse<Void>> deleteFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId) {
        fenceApplicationService.deleteFence(fenceId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @SuppressWarnings("unchecked")
    private List<GpsCoordinate> parseVertices(Object verticesObj) {
        if (verticesObj == null) return List.of();
        List<Map<String, Object>> rawList = (List<Map<String, Object>>) verticesObj;
        return rawList.stream()
                .map(m -> new GpsCoordinate(
                        toBigDecimal(m.get("lng")),
                        toBigDecimal(m.get("lat"))
                ))
                .toList();
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof BigDecimal bd) return bd;
        if (value instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return new BigDecimal(value.toString());
    }
}
