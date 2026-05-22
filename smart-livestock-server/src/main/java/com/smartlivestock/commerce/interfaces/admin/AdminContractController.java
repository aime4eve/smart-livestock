package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.application.dto.ContractResponse;
import com.smartlivestock.commerce.application.query.RevenueQueryService;
import com.smartlivestock.commerce.application.query.SubscriptionQueryService;
import com.smartlivestock.commerce.application.service.ContractApplicationService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Admin contract management — 6 endpoints.
 * All operations require platform_admin role.
 */
@RestController
@RequestMapping("/api/v1/admin/contracts")
@RequiredArgsConstructor
public class AdminContractController {

    private final ContractApplicationService contractApplicationService;
    private final RevenueQueryService revenueQueryService;
    private final SubscriptionQueryService subscriptionQueryService;

    /**
     * GET /api/v1/admin/contracts
     * List active contracts.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<ContractResponse>>> listContracts() {
        requirePlatformAdmin();
        List<ContractResponse> contracts = revenueQueryService.listActiveContracts();
        return ResponseEntity.ok(ApiResponse.ok(contracts));
    }

    /**
     * POST /api/v1/admin/contracts
     * Create a contract draft.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<ContractResponse>> createContract(
            @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        Long tenantId = requireLong(body, "tenantId");
        String contractNumber = requireString(body, "contractNumber");
        String billingModel = requireString(body, "billingModel");
        String effectiveTier = (String) body.get("effectiveTier");
        BigDecimal revenueShareRatio = body.containsKey("revenueShareRatio")
                ? new BigDecimal(body.get("revenueShareRatio").toString())
                : null;

        contractApplicationService.create(tenantId, contractNumber, billingModel,
                effectiveTier, revenueShareRatio);

        ContractResponse contract = subscriptionQueryService.findContractByTenantId(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Contract not found after creation"));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(contract));
    }

    /**
     * GET /api/v1/admin/contracts/{id}
     * Get contract detail.
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ContractResponse>> getContract(@PathVariable Long id) {
        requirePlatformAdmin();
        ContractResponse contract = revenueQueryService.findContractById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Contract not found: " + id));
        return ResponseEntity.ok(ApiResponse.ok(contract));
    }

    /**
     * PUT /api/v1/admin/contracts/{id}
     * Modify a draft contract's billing model, effective tier, or revenue share ratio.
     * Only allowed when the contract is in DRAFT status.
     */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ContractResponse>> updateContract(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        String billingModel = (String) body.get("billingModel");
        String effectiveTier = (String) body.get("effectiveTier");
        BigDecimal revenueShareRatio = body.containsKey("revenueShareRatio")
                ? new BigDecimal(body.get("revenueShareRatio").toString())
                : null;

        contractApplicationService.update(id, billingModel, effectiveTier, revenueShareRatio);

        ContractResponse contract = revenueQueryService.findContractById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Contract not found after update"));
        return ResponseEntity.ok(ApiResponse.ok(contract));
    }

    /**
     * POST /api/v1/admin/contracts/{id}/sign
     * Sign a draft contract.
     */
    @PostMapping("/{id}/sign")
    public ResponseEntity<ApiResponse<ContractResponse>> signContract(@PathVariable Long id) {
        requirePlatformAdmin();
        Long userId = getCurrentUserId();
        contractApplicationService.sign(id, userId);
        ContractResponse contract = revenueQueryService.findContractById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Contract not found after signing"));
        return ResponseEntity.ok(ApiResponse.ok(contract));
    }

    /**
     * PUT /api/v1/admin/contracts/{id}/status
     * Change contract status (suspend / reactivate / terminate).
     */
    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<ContractResponse>> updateStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String targetStatus = body.get("targetStatus");
        if (targetStatus == null || targetStatus.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "targetStatus 不能为空");
        }

        switch (targetStatus.toUpperCase()) {
            case "SUSPENDED" -> contractApplicationService.suspend(id);
            case "ACTIVE" -> contractApplicationService.reactivate(id);
            case "TERMINATED" -> contractApplicationService.terminate(id);
            default -> throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "不支持的目标状态: " + targetStatus);
        }

        ContractResponse contract = revenueQueryService.findContractById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Contract not found after status change"));
        return ResponseEntity.ok(ApiResponse.ok(contract));
    }

    // ── Helpers ────────────────────────────────────────────────────

    private void requirePlatformAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_PLATFORM_ADMIN"));
        if (!isAdmin) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "需要 platform_admin 角色");
        }
    }

    private Long getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof Long userId) {
            return userId;
        }
        throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
    }

    private String requireString(Map<String, Object> body, String field) {
        Object value = body.get(field);
        if (value == null || value.toString().isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, field + " 不能为空");
        }
        return value.toString();
    }

    private Long requireLong(Map<String, Object> body, String field) {
        Object value = body.get(field);
        if (value == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, field + " 不能为空");
        }
        return ((Number) value).longValue();
    }
}
