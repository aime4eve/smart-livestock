package com.smartlivestock.identity.interfaces.admin;

import com.smartlivestock.identity.application.FarmApplicationService;
import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataFarmRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.FarmJpaEntity;
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
 * Admin Farm Management — 4 endpoints.
 * All operations require platform_admin role and operate across tenants.
 */
@RestController
@RequestMapping("/api/v1/admin/farms")
@RequiredArgsConstructor
public class FarmAdminController {

    private final SpringDataFarmRepository springDataFarmRepository;
    private final FarmApplicationService farmApplicationService;
    private final TenantRepository tenantRepository;
    private final UserRepository userRepository;

    /**
     * GET /api/v1/admin/farms
     * Cross-tenant farm list.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listFarms(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Long tenantId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword) {
        requirePlatformAdmin();

        List<FarmJpaEntity> farms;
        if (tenantId != null) {
            farms = springDataFarmRepository.findByTenantId(tenantId);
        } else {
            farms = springDataFarmRepository.findAll();
        }

        List<Map<String, Object>> items = farms.stream()
                .filter(f -> f.getDeletedAt() == null)
                .map(f -> {
                    String tenantName = tenantRepository.findById(f.getTenantId())
                            .map(t -> t.getName())
                            .orElse("");
                    long userCount = userRepository.findByTenantId(f.getTenantId()).size();
                    return Map.<String, Object>of(
                            "id", String.valueOf(f.getId()),
                            "tenantId", String.valueOf(f.getTenantId()),
                            "tenantName", tenantName,
                            "name", f.getName() != null ? f.getName() : "",
                            "status", "active",
                            "livestockCount", 0,
                            "deviceCount", 0,
                            "userCount", userCount,
                            "createdAt", f.getCreatedAt() != null ? f.getCreatedAt().toString() : ""
                    );
                })
                .toList();

        Map<String, Object> data = Map.of(
                "items", items,
                "page", page,
                "pageSize", pageSize,
                "total", items.size()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/admin/farms
     * Create farm for any tenant.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createFarm(@RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        Object tenantIdObj = body.get("tenantId");
        String name = (String) body.get("name");

        if (tenantIdObj == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "tenantId 不能为空");
        }
        if (name == null || name.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "name 不能为空");
        }

        Long tenantId = Long.valueOf(tenantIdObj.toString());

        // Verify tenant exists
        tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + tenantId));

        CreateFarmCommand command = new CreateFarmCommand(
                name,
                toBigDecimal(body.get("latitude")),
                toBigDecimal(body.get("longitude")),
                toBigDecimal(body.get("areaHectares"))
        );
        var farmDto = farmApplicationService.createFarm(tenantId, command, null);

        Map<String, Object> data = Map.<String, Object>of(
                "id", String.valueOf(farmDto.id()),
                "tenantId", String.valueOf(farmDto.tenantId()),
                "name", farmDto.name() != null ? farmDto.name() : "",
                "latitude", farmDto.latitude() != null ? farmDto.latitude() : BigDecimal.ZERO,
                "longitude", farmDto.longitude() != null ? farmDto.longitude() : BigDecimal.ZERO,
                "areaHectares", farmDto.areaHectares() != null ? farmDto.areaHectares() : BigDecimal.ZERO
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/admin/farms/{farmId}
     * Farm detail (admin view with aggregated stats).
     */
    @GetMapping("/{farmId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFarm(@PathVariable Long farmId) {
        requirePlatformAdmin();

        FarmJpaEntity f = springDataFarmRepository.findById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));

        long userCount = userRepository.findByTenantId(f.getTenantId()).size();

        Map<String, Object> data = Map.<String, Object>of(
                "id", String.valueOf(f.getId()),
                "tenantId", String.valueOf(f.getTenantId()),
                "name", f.getName() != null ? f.getName() : "",
                "status", "active",
                "livestockCount", 0,
                "deviceCount", 0,
                "userCount", userCount,
                "activeAlertCount", 0,
                "createdAt", f.getCreatedAt() != null ? f.getCreatedAt().toString() : ""
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * PUT /api/v1/admin/farms/{farmId}/status
     * Enable/disable farm. Idempotent.
     */
    @PutMapping("/{farmId}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateFarmStatus(
            @PathVariable Long farmId,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String status = body.get("status");
        if (status == null || (!status.equals("active") && !status.equals("disabled"))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "status 必须为 active 或 disabled");
        }

        // Verify farm exists
        springDataFarmRepository.findById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));

        // Phase 1 stub: Farm domain model does not yet support status field.
        // Full implementation will update via soft delete or status column.
        Map<String, Object> data = Map.of(
                "id", String.valueOf(farmId),
                "status", status
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof BigDecimal bd) return bd;
        if (value instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return new BigDecimal(value.toString());
    }

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
}
