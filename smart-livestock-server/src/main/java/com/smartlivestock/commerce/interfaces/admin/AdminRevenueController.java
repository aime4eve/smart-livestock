package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.application.dto.RevenuePeriodResponse;
import com.smartlivestock.commerce.application.query.RevenueQueryService;
import com.smartlivestock.commerce.application.service.RevenueApplicationService;
import com.smartlivestock.commerce.infrastructure.persistence.SpringDataRevenuePeriodRepository;
import com.smartlivestock.commerce.application.assembler.RevenuePeriodAssembler;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.RevenuePeriodMapper;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Admin revenue management — 5 endpoints.
 * All operations require platform_admin role.
 */
@RestController
@RequestMapping("/api/v1/admin/revenue")
@RequiredArgsConstructor
public class AdminRevenueController {

    private final RevenueApplicationService revenueApplicationService;
    private final RevenueQueryService revenueQueryService;
    private final SpringDataRevenuePeriodRepository springDataRevenuePeriodRepository;

    /**
     * GET /api/v1/admin/revenue/periods
     * List all revenue periods (cross-tenant admin view).
     */
    @GetMapping("/periods")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listPeriods(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        requirePlatformAdmin();

        List<RevenuePeriodResponse> all = RevenuePeriodAssembler.toResponseList(
                springDataRevenuePeriodRepository.findAll().stream()
                        .map(RevenuePeriodMapper::toDomain)
                        .toList());

        Map<String, Object> data = Map.of(
                "items", all,
                "page", page,
                "pageSize", pageSize,
                "total", all.size()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/admin/revenue/periods/{id}
     * Get revenue period detail.
     */
    @GetMapping("/periods/{id}")
    public ResponseEntity<ApiResponse<RevenuePeriodResponse>> getPeriod(@PathVariable Long id) {
        requirePlatformAdmin();
        RevenuePeriodResponse period = revenueQueryService.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Revenue period not found: " + id));
        return ResponseEntity.ok(ApiResponse.ok(period));
    }

    /**
     * POST /api/v1/admin/revenue/calculate
     * Trigger monthly revenue calculation for a contract.
     */
    @PostMapping("/calculate")
    public ResponseEntity<ApiResponse<RevenuePeriodResponse>> calculate(
            @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        Long contractId = requireLong(body, "contractId");
        String periodStartStr = requireString(body, "periodStart");
        String periodEndStr = requireString(body, "periodEnd");
        int grossAmountCents = requireInt(body, "grossAmountCents");

        revenueApplicationService.calculatePeriod(
                contractId,
                LocalDate.parse(periodStartStr),
                LocalDate.parse(periodEndStr),
                grossAmountCents);

        // Return the latest period for this contract
        List<RevenuePeriodResponse> periods = revenueQueryService.listByContractId(contractId);
        if (periods.isEmpty()) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR, "Revenue period not created");
        }
        return ResponseEntity.ok(ApiResponse.ok(periods.getLast()));
    }

    /**
     * POST /api/v1/admin/revenue/periods/{id}/confirm
     * Platform confirms a revenue period.
     */
    @PostMapping("/periods/{id}/confirm")
    public ResponseEntity<ApiResponse<RevenuePeriodResponse>> confirmByPlatform(
            @PathVariable Long id) {
        requirePlatformAdmin();
        revenueApplicationService.confirmByPlatform(id);
        RevenuePeriodResponse period = revenueQueryService.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Revenue period not found: " + id));
        return ResponseEntity.ok(ApiResponse.ok(period));
    }

    /**
     * POST /api/v1/admin/revenue/periods/{id}/recalculate
     * Recalculate a revenue period with new amounts.
     */
    @PostMapping("/periods/{id}/recalculate")
    public ResponseEntity<ApiResponse<RevenuePeriodResponse>> recalculate(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();
        int grossAmountCents = requireInt(body, "grossAmountCents");
        revenueApplicationService.recalculate(id, grossAmountCents);
        RevenuePeriodResponse period = revenueQueryService.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Revenue period not found: " + id));
        return ResponseEntity.ok(ApiResponse.ok(period));
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

    private int requireInt(Map<String, Object> body, String field) {
        Object value = body.get(field);
        if (value == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, field + " 不能为空");
        }
        return ((Number) value).intValue();
    }
}
