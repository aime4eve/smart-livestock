package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.FenceZoneApplicationService;
import com.smartlivestock.ranch.application.dto.FenceZoneDto;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
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
@RequestMapping("/api/v1/farms/{farmId}/fence-zones")
@RequiredArgsConstructor
public class FenceZoneController {

    private final FenceZoneApplicationService fenceZoneService;
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
    public ResponseEntity<ApiResponse<Map<String, Object>>> listFenceZones(
            @PathVariable Long farmId) {
        verifyFarmOwnership(farmId);
        List<FenceZoneDto> zones = fenceZoneService.listByFarm(farmId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("items", zones)));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<FenceZoneDto>> createFenceZone(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        verifyFarmOwnership(farmId);
        Long fenceId = ((Number) body.get("fenceId")).longValue();
        String name = (String) body.get("name");
        String zoneType = (String) body.get("zoneType");
        List<GpsCoordinate> vertices = parseVertices(body.get("vertices"));
        int alertRadius = body.get("alertRadius") != null ? ((Number) body.get("alertRadius")).intValue() : 20;
        String severity = (String) body.getOrDefault("severity", "INFO");

        FenceZoneDto zone = fenceZoneService.create(farmId, fenceId, name, zoneType, vertices, alertRadius, severity);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(zone));
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
