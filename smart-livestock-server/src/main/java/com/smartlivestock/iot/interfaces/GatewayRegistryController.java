package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.GatewayRegistryService;
import com.smartlivestock.iot.domain.model.GatewayRegistry;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * Farm-scoped gateway position endpoints (NIX-219 F1/F2).
 * Discovery lists gateways the farm's devices actually talk to; marking a
 * position is a globally-unique upsert (later markers overwrite, with confirm).
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/gateways")
@RequiredArgsConstructor
public class GatewayRegistryController {

    private final GatewayRegistryService gatewayRegistryService;
    private final IdentityQueryPort identityQueryPort;

    @GetMapping
    @PreAuthorize("hasAnyRole('OWNER', 'WORKER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<List<GatewayRegistryService.GatewayDiscoveryItem>>> discover(
            @PathVariable Long farmId) {
        verifyFarmOwnership(farmId);
        return ResponseEntity.ok(ApiResponse.ok(gatewayRegistryService.discoverFarmGateways(farmId)));
    }

    @PutMapping("/{gatewayId}/position")
    @PreAuthorize("hasAnyRole('OWNER', 'WORKER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> markPosition(
            @PathVariable Long farmId,
            @PathVariable String gatewayId,
            @RequestBody MarkPositionRequest request) {
        verifyFarmOwnership(farmId);
        GatewayRegistryService.MarkResult result = gatewayRegistryService.markPosition(
                gatewayId,
                request.latitude(),
                request.longitude(),
                currentUserId(),
                "APP");
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "gatewayId", gatewayId,
                "overwritten", result.overwritten(),
                "previousMarkedBy", result.previousMarkedBy() != null ? result.previousMarkedBy() : 0,
                "previousMarkedAt", result.previousMarkedAt() != null ? result.previousMarkedAt().toString() : "",
                "latitude", result.registry().getLatitude(),
                "longitude", result.registry().getLongitude())));
    }

    private void verifyFarmOwnership(Long farmId) {
        var farm = identityQueryPort.findFarmById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        Long currentTenant = TenantContext.getCurrentTenant();
        if (currentTenant != null && !farm.tenantId().equals(currentTenant)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
    }

    private Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        return (Long) authentication.getPrincipal();
    }

    public record MarkPositionRequest(double latitude, double longitude) {
    }
}
