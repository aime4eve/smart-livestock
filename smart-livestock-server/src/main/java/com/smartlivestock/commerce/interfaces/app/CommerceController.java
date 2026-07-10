package com.smartlivestock.commerce.interfaces.app;

import com.smartlivestock.commerce.application.dto.ContractResponse;
import com.smartlivestock.commerce.application.dto.RevenuePeriodResponse;
import com.smartlivestock.commerce.application.query.RevenueQueryService;
import com.smartlivestock.commerce.application.query.SubscriptionQueryService;
import com.smartlivestock.commerce.application.service.RevenueApplicationService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * App-facing commerce endpoints — 3 endpoints.
 * Provides contract and revenue views for the authenticated tenant (partner view).
 */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class CommerceController {

    private final SubscriptionQueryService subscriptionQueryService;
    private final RevenueQueryService revenueQueryService;
    private final RevenueApplicationService revenueApplicationService;

    /**
     * GET /api/v1/contracts/me
     * Get contract for the current tenant (partner's view).
     */
    @GetMapping("/contracts/me")
    public ResponseEntity<ApiResponse<ContractResponse>> getMyContract() {
        Long tenantId = requireTenantId();
        ContractResponse contract = subscriptionQueryService.findContractByTenantId(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Contract not found for tenant: " + tenantId));
        return ResponseEntity.ok(ApiResponse.ok(contract));
    }

    /**
     * GET /api/v1/revenue/periods
     * List revenue periods for the current tenant.
     */
    @GetMapping("/revenue/periods")
    public ResponseEntity<ApiResponse<List<RevenuePeriodResponse>>> listRevenuePeriods() {
        Long tenantId = requireTenantId();
        List<RevenuePeriodResponse> periods = revenueQueryService.listByTenantId(tenantId);
        return ResponseEntity.ok(ApiResponse.ok(periods));
    }

    /**
     * POST /api/v1/revenue/periods/{id}/confirm
     * Partner confirms a revenue period.
     */
    @PostMapping("/revenue/periods/{id}/confirm")
    public ResponseEntity<ApiResponse<RevenuePeriodResponse>> confirmByPartner(
            @PathVariable Long id) {
        Long tenantId = requireTenantId();
        RevenuePeriodResponse existing = revenueQueryService.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Revenue period not found: " + id));
        if (!tenantId.equals(existing.getTenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权操作此结算周期");
        }
        revenueApplicationService.confirmByPartner(id);
        RevenuePeriodResponse period = revenueQueryService.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Revenue period not found: " + id));
        return ResponseEntity.ok(ApiResponse.ok(period));
    }

    // ── Helpers ────────────────────────────────────────────────────

    private Long requireTenantId() {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证或缺少租户信息");
        }
        return tenantId;
    }
}
