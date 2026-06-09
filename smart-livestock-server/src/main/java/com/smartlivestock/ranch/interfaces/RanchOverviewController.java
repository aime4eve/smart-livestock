package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.RanchOverviewApplicationService;
import com.smartlivestock.ranch.application.dto.RanchOverviewDto.RanchOverviewResponse;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/farms/{farmId}")
@RequiredArgsConstructor
public class RanchOverviewController {

    private final RanchOverviewApplicationService ranchOverviewService;
    private final IdentityQueryPort identityQueryPort;

    private void verifyFarmOwnership(Long farmId) {
        var farm = identityQueryPort.findFarmById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        Long currentTenant = TenantContext.getCurrentTenant();
        if (currentTenant != null && !farm.tenantId().equals(currentTenant)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
    }

    @GetMapping("/ranch-overview")
    public ResponseEntity<ApiResponse<RanchOverviewResponse>> getOverview(@PathVariable Long farmId) {
        verifyFarmOwnership(farmId);
        return ResponseEntity.ok(ApiResponse.ok(ranchOverviewService.getOverview(farmId)));
    }
}
