package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.application.FarmApplicationService;
import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
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
import java.util.*;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class FarmController {

    private final FarmApplicationService farmApplicationService;
    private final UserRepository userRepository;
    private final UserFarmAssignmentRepository userFarmAssignmentRepository;

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

    @SuppressWarnings("unchecked")
    @PostMapping("/farms")
    public ResponseEntity<ApiResponse<FarmDto>> createFarm(@RequestBody Map<String, Object> body) {
        Long userId = getCurrentUserId();

        var userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "用户不存在");
        }
        var user = userOpt.get();
        if (!user.isOwner() && !user.getRole().name().equals("B2B_ADMIN")) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "仅 owner 或 b2b_admin 可创建牧场");
        }

        String name = (String) body.get("name");
        if (name == null || name.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "牧场名称不能为空");
        }

        Long tenantId = TenantContext.getCurrentTenant();
        List<FarmDto> existingFarms = farmApplicationService.listFarms(tenantId);
        boolean duplicate = existingFarms.stream()
                .anyMatch(f -> name.equals(f.name()));
        if (duplicate) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "牧场名称已存在");
        }

        List<GpsCoordinate> boundaryVertices = null;
        if (body.get("boundaryVertices") != null) {
            boundaryVertices = parseVertices(body.get("boundaryVertices"));
        }

        CreateFarmCommand command = new CreateFarmCommand(
                name,
                toBigDecimal(body.get("latitude")),
                toBigDecimal(body.get("longitude")),
                toBigDecimal(body.get("areaHectares")),
                boundaryVertices
        );
        Long ownerId = null;
        if (body.get("ownerId") != null) {
            ownerId = ((Number) body.get("ownerId")).longValue();
        } else if (user.isOwner()) {
            ownerId = userId;
        }
        FarmDto farm = farmApplicationService.createFarm(tenantId, command, ownerId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(farm));
    }

    @GetMapping("/farms/{farmId}")
    public ResponseEntity<ApiResponse<FarmDto>> getFarm(@PathVariable Long farmId) {
        FarmDto farm = farmApplicationService.getFarm(farmId);
        return ResponseEntity.ok(ApiResponse.ok(farm));
    }

    @PutMapping("/farms/{farmId}")
    public ResponseEntity<ApiResponse<FarmDto>> updateFarm(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        FarmDto farm = farmApplicationService.getFarm(farmId);
        return ResponseEntity.ok(ApiResponse.ok(farm));
    }

    @GetMapping("/farms/{farmId}/members")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listMembers(@PathVariable Long farmId) {
        List<UserFarmAssignmentJpaEntity> assignments =
                userFarmAssignmentRepository.findByFarmIdAndStatus(farmId, "ACTIVE");

        List<Map<String, Object>> items = assignments.stream().map(a -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("userId", a.getUserId());
            item.put("farmId", a.getFarmId());
            item.put("role", a.getRole());
            item.put("status", a.getStatus());
            item.put("assignedAt", a.getCreatedAt() != null ? a.getCreatedAt().toString() : null);
            userRepository.findById(a.getUserId()).ifPresent(user -> {
                item.put("name", user.getName());
                item.put("phone", user.getPhone());
            });
            return item;
        }).toList();

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", items);
        data.put("page", 1);
        data.put("pageSize", items.size());
        data.put("total", items.size());
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    @PostMapping("/farms/{farmId}/members")
    public ResponseEntity<ApiResponse<Map<String, Object>>> addMember(
            @PathVariable Long farmId,
            @RequestBody Map<String, String> body) {
        Long userId = Long.valueOf(body.get("userId"));
        String role = body.getOrDefault("role", "WORKER");

        if (userFarmAssignmentRepository.existsByUserIdAndFarmId(userId, farmId)) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "用户已在该牧场中");
        }
        userFarmAssignmentRepository.save(userId, farmId, role, "ACTIVE");

        Map<String, Object> data = Map.of("userId", userId, "farmId", farmId, "role", role);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(data));
    }

    @DeleteMapping("/farms/{farmId}/members/{userId}")
    public ResponseEntity<ApiResponse<Void>> removeMember(
            @PathVariable Long farmId,
            @PathVariable Long userId) {
        if (!userFarmAssignmentRepository.existsByUserIdAndFarmId(userId, farmId)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不在该牧场中");
        }
        userFarmAssignmentRepository.updateStatus(userId, farmId, "DISABLED");
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    /**
     * PUT /api/v1/farms/{farmId}/owner
     * 变更牧场主（B2B Admin 使用）。
     */
    @PutMapping("/farms/{farmId}/owner")
    public ResponseEntity<ApiResponse<Map<String, Object>>> changeOwner(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        Long tenantId = TenantContext.getCurrentTenant();
        Object ownerIdObj = body.get("ownerId");
        if (ownerIdObj == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "ownerId 不能为空");
        }
        Long newOwnerId = ((Number) ownerIdObj).longValue();

        // Verify new owner belongs to same tenant
        User newOwner = userRepository.findById(newOwnerId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在: " + newOwnerId));
        if (!tenantId.equals(newOwner.getTenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "不能跨租户变更牧场主");
        }

        // Remove current owner assignment
        userFarmAssignmentRepository.findByFarmIdAndRoleAndStatus(farmId, "OWNER", "ACTIVE")
                .ifPresent(current -> userFarmAssignmentRepository.updateStatus(
                        current.getUserId(), farmId, "DISABLED"));

        // Create or reactivate new owner assignment
        var existingAssignment = userFarmAssignmentRepository.findByUserIdAndFarmId(newOwnerId, farmId);
        if (existingAssignment.isPresent()) {
            userFarmAssignmentRepository.updateRoleAndStatus(newOwnerId, farmId, "OWNER", "ACTIVE");
        } else {
            userFarmAssignmentRepository.save(newOwnerId, farmId, "OWNER", "ACTIVE");
        }

        Map<String, Object> data = Map.of("farmId", farmId, "ownerId", newOwnerId);
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    @SuppressWarnings("unchecked")
    private List<GpsCoordinate> parseVertices(Object verticesObj) {
        if (verticesObj == null) return List.of();
        List<Map<String, Object>> rawList = (List<Map<String, Object>>) verticesObj;
        return rawList.stream()
                .map(m -> new GpsCoordinate(
                        toBigDecimal(m.get("lat")),
                        toBigDecimal(m.get("lng"))
                ))
                .toList();
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
