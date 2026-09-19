package com.smartlivestock.iot.interfaces.admin;

import com.smartlivestock.iot.application.GatewayRegistryService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * F10 admin gateway reconciliation view (NIX-219): registered positions,
 * gateways seen in telemetry but never marked, and the overall mark rate.
 */
@RestController
@RequestMapping("/api/v1/admin/gateways")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")
public class GatewayAdminController {

    private final GatewayRegistryService gatewayRegistryService;

    @GetMapping("/overview")
    public ResponseEntity<ApiResponse<GatewayRegistryService.AdminGatewayOverview>> overview() {
        return ResponseEntity.ok(ApiResponse.ok(gatewayRegistryService.adminOverview()));
    }
}
