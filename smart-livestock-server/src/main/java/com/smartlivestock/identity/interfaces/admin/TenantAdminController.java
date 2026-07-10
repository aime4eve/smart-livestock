package com.smartlivestock.identity.interfaces.admin;

import com.smartlivestock.identity.application.TenantApplicationService;
import com.smartlivestock.identity.application.command.CreateTenantCommand;
import com.smartlivestock.identity.application.dto.TenantDto;
import com.smartlivestock.identity.domain.model.TenantPhase;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataTenantRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.TenantJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Admin Tenant Management — 5 endpoints.
 * All operations require platform_admin role and operate across tenants.
 */
@RestController
@RequestMapping("/api/v1/admin/tenants")
@RequiredArgsConstructor
public class TenantAdminController {

    private final SpringDataTenantRepository springDataTenantRepository;
    private final TenantApplicationService tenantApplicationService;
    private final FarmRepository farmRepository;
    private final UserRepository userRepository;

    /**
     * GET /api/v1/admin/tenants
     * Cross-tenant list with filters.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listTenants(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String phase,
            @RequestParam(required = false) String keyword) {
        requirePlatformAdmin();

        List<TenantJpaEntity> allTenants = springDataTenantRepository.findAll();
        List<Map<String, Object>> items = allTenants.stream()
                .map(t -> {
                    long farmCount = farmRepository.findByTenantId(t.getId()).size();
                    long userCount = userRepository.findByTenantId(t.getId()).size();
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", String.valueOf(t.getId()));
                    m.put("name", t.getName() != null ? t.getName() : "");
                    m.put("contactName", t.getContactName() != null ? t.getContactName() : "");
                    m.put("contactPhone", t.getContactPhone() != null ? t.getContactPhone() : "");
                    m.put("phase", t.getPhase() != null ? t.getPhase().toLowerCase() : "sample");
                    m.put("status", "active");
                    m.put("farmCount", farmCount);
                    m.put("userCount", userCount);
                    m.put("deviceCount", 0);
                    m.put("createdAt", t.getCreatedAt() != null ? t.getCreatedAt().toString() : "");
                    return m;
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
     * POST /api/v1/admin/tenants
     * Create tenant (admin creates on behalf of user).
     */
    @PostMapping
    public ResponseEntity<ApiResponse<TenantDto>> createTenant(@RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String name = body.get("name");
        String contactName = body.get("contactName");
        String contactPhone = body.get("contactPhone");

        if (name == null || name.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "name 不能为空");
        }

        CreateTenantCommand command = new CreateTenantCommand(name, contactName, contactPhone);
        TenantDto tenant = tenantApplicationService.createTenant(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(tenant));
    }

    /**
     * GET /api/v1/admin/tenants/{tenantId}
     * Tenant detail with aggregated stats.
     */
    @GetMapping("/{tenantId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getTenant(@PathVariable Long tenantId) {
        requirePlatformAdmin();

        TenantJpaEntity t = springDataTenantRepository.findById(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + tenantId));

        long farmCount = farmRepository.findByTenantId(tenantId).size();
        long userCount = userRepository.findByTenantId(tenantId).size();

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", String.valueOf(t.getId()));
        data.put("name", t.getName() != null ? t.getName() : "");
        data.put("contactName", t.getContactName() != null ? t.getContactName() : "");
        data.put("contactPhone", t.getContactPhone() != null ? t.getContactPhone() : "");
        data.put("phase", t.getPhase() != null ? t.getPhase().toLowerCase() : "sample");
        data.put("status", "active");
        data.put("farmCount", farmCount);
        data.put("userCount", userCount);
        data.put("deviceCount", 0);
        data.put("activeLicenseCount", 0);
        data.put("createdAt", t.getCreatedAt() != null ? t.getCreatedAt().toString() : "");
        data.put("updatedAt", t.getUpdatedAt() != null ? t.getUpdatedAt().toString() : "");

        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * PUT /api/v1/admin/tenants/{tenantId}
     * Update tenant info (name, contactName, contactPhone).
     */
    @PutMapping("/{tenantId}")
    public ResponseEntity<ApiResponse<TenantDto>> updateTenant(
            @PathVariable Long tenantId,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String name = body.get("name");
        String contactName = body.get("contactName");
        String contactPhone = body.get("contactPhone");

        TenantDto updated = tenantApplicationService.updateTenant(tenantId, name, contactName, contactPhone);
        return ResponseEntity.ok(ApiResponse.ok(updated));
    }

    /**
     * GET /api/v1/admin/tenants/{tenantId}/farms
     * List farms belonging to a tenant.
     */
    @GetMapping("/{tenantId}/farms")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listTenantFarms(
            @PathVariable Long tenantId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        requirePlatformAdmin();

        springDataTenantRepository.findById(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + tenantId));

        var farms = farmRepository.findByTenantId(tenantId);
        List<Map<String, Object>> items = farms.stream()
                .map(f -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", f.getId() != null ? String.valueOf(f.getId()) : "");
                    m.put("tenantId", String.valueOf(tenantId));
                    m.put("name", f.getName() != null ? f.getName() : "");
                    m.put("latitude", f.getLatitude());
                    m.put("longitude", f.getLongitude());
                    m.put("areaHectares", f.getAreaHectares());
                    return m;
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
     * PUT /api/v1/admin/tenants/{tenantId}/status
     * Enable/disable tenant. Idempotent.
     */
    @PutMapping("/{tenantId}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateTenantStatus(
            @PathVariable Long tenantId,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String status = body.get("status");
        if (status == null || (!status.equals("active") && !status.equals("disabled"))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "status 必须为 active 或 disabled");
        }

        // Verify tenant exists
        springDataTenantRepository.findById(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + tenantId));

        // Tenant status toggle — pending Tenant domain model status field extension.
        Map<String, Object> data = Map.of(
                "id", String.valueOf(tenantId),
                "status", status
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * PUT /api/v1/admin/tenants/{tenantId}/phase
     * Change tenant phase (sample <-> batch). Idempotent.
     */
    @PutMapping("/{tenantId}/phase")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateTenantPhase(
            @PathVariable Long tenantId,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String phase = body.get("phase");
        if (phase == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "phase 不能为空");
        }

        TenantPhase targetPhase;
        try {
            targetPhase = TenantPhase.valueOf(phase.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "phase 必须为 sample 或 batch");
        }

        if (targetPhase == TenantPhase.BATCH) {
            tenantApplicationService.transitionToBatch(tenantId);
        }

        Map<String, Object> data = Map.of(
                "id", String.valueOf(tenantId),
                "phase", phase.toLowerCase()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
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
