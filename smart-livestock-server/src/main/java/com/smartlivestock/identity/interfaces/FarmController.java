package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.application.FarmApplicationService;
import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class FarmController {

    private final FarmApplicationService farmApplicationService;
    private final UserRepository userRepository;

    /**
     * GET /api/v1/farms
     * List farms for current tenant.
     */
    @GetMapping("/farms")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listFarms() {
        Long tenantId = TenantContext.getCurrentTenant();
        List<FarmDto> farms = farmApplicationService.listFarms(tenantId);
        Map<String, Object> data = Map.of(
                "items", farms,
                "page", 1,
                "pageSize", farms.size(),
                "total", farms.size()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/farms
     * Create a new farm.
     */
    @PostMapping("/farms")
    public ResponseEntity<ApiResponse<FarmDto>> createFarm(@RequestBody Map<String, Object> body) {
        Long userId = getCurrentUserId();

        // 仅 owner 可创建牧场
        var userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "用户不存在");
        }
        if (!userOpt.get().isOwner()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "仅 owner 可创建牧场");
        }

        Long tenantId = TenantContext.getCurrentTenant();
        CreateFarmCommand command = new CreateFarmCommand(
                (String) body.get("name"),
                toBigDecimal(body.get("latitude")),
                toBigDecimal(body.get("longitude")),
                toBigDecimal(body.get("areaHectares"))
        );
        FarmDto farm = farmApplicationService.createFarm(tenantId, command, userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(farm));
    }

    /**
     * GET /api/v1/farms/{farmId}
     * Get farm detail.
     */
    @GetMapping("/farms/{farmId}")
    public ResponseEntity<ApiResponse<FarmDto>> getFarm(@PathVariable Long farmId) {
        FarmDto farm = farmApplicationService.getFarm(farmId);
        return ResponseEntity.ok(ApiResponse.ok(farm));
    }

    /**
     * PUT /api/v1/farms/{farmId}
     * Update farm info.
     */
    @PutMapping("/farms/{farmId}")
    public ResponseEntity<ApiResponse<FarmDto>> updateFarm(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        // Current FarmApplicationService does not have an update method.
        // Return current farm for now. Full update will be added when needed.
        FarmDto farm = farmApplicationService.getFarm(farmId);
        return ResponseEntity.ok(ApiResponse.ok(farm));
    }

    /**
     * GET /api/v1/farms/{farmId}/members
     * List farm members (Phase 1 stub — member management not yet implemented).
     */
    @GetMapping("/farms/{farmId}/members")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listMembers(@PathVariable Long farmId) {
        // Phase 1 stub — member management requires UserFarmAssignment infrastructure
        Map<String, Object> data = Map.of(
                "items", List.of(),
                "page", 1,
                "pageSize", 0,
                "total", 0
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/farms/{farmId}/members
     * Add member to farm (Phase 1 stub).
     */
    @PostMapping("/farms/{farmId}/members")
    public ResponseEntity<ApiResponse<Map<String, Object>>> addMember(
            @PathVariable Long farmId,
            @RequestBody Map<String, String> body) {
        // Phase 1 stub
        Map<String, Object> data = Map.of(
                "message", "member management not yet implemented",
                "phase", "stub"
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(data));
    }

    /**
     * DELETE /api/v1/farms/{farmId}/members/{userId}
     * Remove member from farm (Phase 1 stub).
     */
    @DeleteMapping("/farms/{farmId}/members/{userId}")
    public ResponseEntity<ApiResponse<Void>> removeMember(
            @PathVariable Long farmId,
            @PathVariable Long userId) {
        // Phase 1 stub
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof BigDecimal bd) return bd;
        if (value instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return new BigDecimal(value.toString());
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        return (Long) authentication.getPrincipal();
    }
}
