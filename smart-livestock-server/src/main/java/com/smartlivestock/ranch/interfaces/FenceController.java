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
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/fences")
@RequiredArgsConstructor
public class FenceController {

    private final FenceApplicationService fenceApplicationService;
    private final IdentityQueryPort identityQueryPort;

    private void verifyFarmOwnership(Long farmId) {
        var farm = identityQueryPort.findFarmById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        Long currentTenant = TenantContext.getCurrentTenant();
        if (currentTenant != null && !farm.tenantId().equals(currentTenant)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listFences(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        verifyFarmOwnership(farmId);
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
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    @QuotaCheck(feature = "fence_management")
    public ResponseEntity<ApiResponse<FenceDto>> createFence(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        verifyFarmOwnership(farmId);
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
        verifyFarmOwnership(farmId);
        FenceDto fence = fenceApplicationService.getFence(fenceId);
        return ResponseEntity.ok(ApiResponse.ok(fence));
    }

    @SuppressWarnings("unchecked")
    @PutMapping("/{fenceId}")
    public ResponseEntity<? extends ApiResponse<?>> updateFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId,
            @RequestBody Map<String, Object> body) {
        verifyFarmOwnership(farmId);
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
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    public ResponseEntity<ApiResponse<FenceDto>> forceUpdateFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId,
            @RequestBody Map<String, Object> body) {
        verifyFarmOwnership(farmId);
        int version = ((Number) body.get("version")).intValue();
        FenceDto fence = fenceApplicationService.forceUpdateFence(fenceId,
                parseVertices(body.get("vertices")),
                (String) body.get("name"),
                (String) body.get("color"),
                version);
        return ResponseEntity.ok(ApiResponse.ok(fence));
    }

    @DeleteMapping("/{fenceId}")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId) {
        verifyFarmOwnership(farmId);
        fenceApplicationService.deleteFence(fenceId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @SuppressWarnings("unchecked")
    private List<GpsCoordinate> parseVertices(Object verticesObj) {
        if (verticesObj == null) return List.of();
        List<Map<String, Object>> rawList = (List<Map<String, Object>>) verticesObj;
        return rawList.stream()
                .map(m -> new GpsCoordinate(
                        toBigDecimal(m.getOrDefault("lat", m.get("latitude"))),
                        toBigDecimal(m.getOrDefault("lng", m.get("longitude")))
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
