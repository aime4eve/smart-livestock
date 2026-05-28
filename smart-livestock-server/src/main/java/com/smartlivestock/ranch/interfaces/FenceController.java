package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.command.CreateFenceCommand;
import com.smartlivestock.ranch.application.command.UpdateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.platform.web.QuotaCheck;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
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

    @PostMapping
    @QuotaCheck(feature = "fence_management")
    public ResponseEntity<ApiResponse<FenceDto>> createFence(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        CreateFenceCommand command = new CreateFenceCommand(
                farmId,
                (String) body.get("name"),
                parseVertices(body.get("vertices")),
                (String) body.get("color"),
                (String) body.get("fenceType")
        );
        FenceDto fence = fenceApplicationService.createFence(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(fence));
    }

    @GetMapping("/{fenceId}")
    public ResponseEntity<ApiResponse<FenceDto>> getFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId) {
        FenceDto fence = fenceApplicationService.getFence(fenceId);
        return ResponseEntity.ok(ApiResponse.ok(fence));
    }

    @SuppressWarnings("unchecked")
    @PutMapping("/{fenceId}")
    public ResponseEntity<? extends ApiResponse<?>> updateFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId,
            @RequestBody Map<String, Object> body) {
        Integer expectedVersion = body.get("expectedVersion") != null
                ? ((Number) body.get("expectedVersion")).intValue() : null;
        UpdateFenceCommand command = new UpdateFenceCommand(
                (String) body.get("name"),
                parseVertices(body.get("vertices")),
                (String) body.get("color"),
                expectedVersion
        );
        try {
            FenceDto fence = fenceApplicationService.updateFence(fenceId, command);
            return ResponseEntity.ok(ApiResponse.ok(fence));
        } catch (ApiException e) {
            if (e.getCode() == ErrorCode.STATE_CONFLICT) {
                FenceDto current = fenceApplicationService.getFence(fenceId);
                Map<String, Object> conflictData = Map.of(
                        "serverVersion", current.version(),
                        "serverVertices", current.vertices()
                );
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(ApiResponse.errorWithData(ErrorCode.STATE_CONFLICT, e.getMessage(), conflictData));
            }
            throw e;
        }
    }

    @PutMapping("/{fenceId}/force")
    public ResponseEntity<ApiResponse<FenceDto>> forceUpdateFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId,
            @RequestBody Map<String, Object> body) {
        int version = ((Number) body.get("version")).intValue();
        FenceDto fence = fenceApplicationService.forceUpdateFence(fenceId,
                parseVertices(body.get("vertices")),
                (String) body.get("name"),
                (String) body.get("color"),
                version);
        return ResponseEntity.ok(ApiResponse.ok(fence));
    }

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
                        toBigDecimal(m.get("lat")),
                        toBigDecimal(m.get("lng"))
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
