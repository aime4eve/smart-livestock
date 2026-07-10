package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.LivestockApplicationService;
import com.smartlivestock.ranch.application.command.CreateLivestockCommand;
import com.smartlivestock.ranch.application.command.UpdateLivestockCommand;
import com.smartlivestock.ranch.application.dto.LivestockDto;
import com.smartlivestock.platform.web.QuotaCheck;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/livestock")
@RequiredArgsConstructor
public class LivestockController {

    private final LivestockApplicationService livestockApplicationService;

    /**
     * GET /api/v1/farms/{farmId}/livestock
     * List livestock for a farm with optional filters.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listLivestock(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String gender,
            @RequestParam(required = false) String status) {
        var result = livestockApplicationService.listByFarm(farmId, keyword, page, pageSize);
        Map<String, Object> data = Map.of(
                "items", result.items(),
                "page", result.page(),
                "pageSize", result.pageSize(),
                "total", result.total()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/farms/{farmId}/livestock
     * Create a new livestock.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    @QuotaCheck(feature = "livestock_management")
    public ResponseEntity<ApiResponse<LivestockDto>> createLivestock(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
       String livestockCode = (String) body.get("livestockCode");
        CreateLivestockCommand command = new CreateLivestockCommand(
                farmId,
                (String) body.get("livestockCode"),
                (String) body.get("breed"),
                (String) body.get("gender"),
                body.get("birthDate") != null ? LocalDate.parse((String) body.get("birthDate")) : null,
                body.get("weight") != null ? new BigDecimal(body.get("weight").toString()) : null
        );
        LivestockDto livestock = livestockApplicationService.createLivestock(command);
       return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(livestock));
    }

    /**
     * GET /api/v1/farms/{farmId}/livestock/{livestockId}
     * Get livestock detail.
     */
    @GetMapping("/{livestockId}")
    public ResponseEntity<ApiResponse<LivestockDto>> getLivestock(
            @PathVariable Long farmId,
            @PathVariable Long livestockId) {
        LivestockDto livestock = livestockApplicationService.getLivestock(livestockId);
        return ResponseEntity.ok(ApiResponse.ok(livestock));
    }

    /**
     * PUT /api/v1/farms/{farmId}/livestock/{livestockId}
     * Update livestock info.
     */
    @PutMapping("/{livestockId}")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<LivestockDto>> updateLivestock(
            @PathVariable Long farmId,
            @PathVariable Long livestockId,
            @RequestBody Map<String, Object> body) {
       // Current service only supports create/get/list/delete/updatePosition.
       // Return current livestock for now. Full update will be added when needed.
        UpdateLivestockCommand command = new UpdateLivestockCommand(
                (String) body.get("livestockCode"),
                (String) body.get("breed"),
                (String) body.get("gender"),
                body.get("birthDate") != null ? LocalDate.parse((String) body.get("birthDate")) : null,
                body.get("weight") != null ? new BigDecimal(body.get("weight").toString()) : null
        );
        LivestockDto livestock = livestockApplicationService.updateLivestock(livestockId, command);
       return ResponseEntity.ok(ApiResponse.ok(livestock));
    }

    /**
     * DELETE /api/v1/farms/{farmId}/livestock/{livestockId}
     * Delete (soft delete) livestock.
     */
    @DeleteMapping("/{livestockId}")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteLivestock(
            @PathVariable Long farmId,
            @PathVariable Long livestockId) {
        livestockApplicationService.deleteLivestock(livestockId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
