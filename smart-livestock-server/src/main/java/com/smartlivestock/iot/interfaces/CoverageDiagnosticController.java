package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.CoverageDiagnosticService;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * F8 coverage diagnostics for one farm (NIX-219): tier percentages, 100m heat
 * cells, and rule-based gateway relocation advice (direction/cluster + what-if).
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/coverage-diagnostics")
@RequiredArgsConstructor
public class CoverageDiagnosticController {

    private final CoverageDiagnosticService coverageDiagnosticService;
    private final IdentityQueryPort identityQueryPort;

    @GetMapping
    @PreAuthorize("hasAnyRole('OWNER', 'WORKER', 'B2B_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<ApiResponse<CoverageDiagnosticService.CoverageDiagnostic>> diagnose(
            @PathVariable Long farmId) {
        var farm = identityQueryPort.findFarmById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        Long currentTenant = TenantContext.getCurrentTenant();
        if (currentTenant != null && !farm.tenantId().equals(currentTenant)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
        return ResponseEntity.ok(ApiResponse.ok(coverageDiagnosticService.diagnose(farmId)));
    }
}
