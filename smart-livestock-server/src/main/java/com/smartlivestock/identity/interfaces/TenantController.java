package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.application.TenantApplicationService;
import com.smartlivestock.identity.application.dto.TenantDto;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/tenants")
@RequiredArgsConstructor
public class TenantController {

    private final TenantApplicationService tenantApplicationService;

    /**
     * GET /api/v1/tenants/me
     * Get current tenant info.
     */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<TenantDto>> getCurrentTenant() {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(ErrorCode.RESOURCE_NOT_FOUND, "当前用户无租户归属", null));
        }
        TenantDto tenant = tenantApplicationService.getTenant(tenantId);
        return ResponseEntity.ok(ApiResponse.ok(tenant));
    }

    /**
     * PUT /api/v1/tenants/me
     * Update current tenant info.
     */
    @PutMapping("/me")
    public ResponseEntity<ApiResponse<TenantDto>> updateCurrentTenant(@RequestBody Map<String, String> body) {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(ErrorCode.RESOURCE_NOT_FOUND, "当前用户无租户归属", null));
        }
        TenantDto tenant = tenantApplicationService.getTenant(tenantId);
        return ResponseEntity.ok(ApiResponse.ok(tenant));
    }
}
