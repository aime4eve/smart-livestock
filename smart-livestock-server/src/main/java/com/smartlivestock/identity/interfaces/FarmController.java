package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.application.FarmApplicationService;
import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.repository.UserRepository;
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
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class FarmController {

    private final FarmApplicationService farmApplicationService;
    private final UserRepository userRepository;

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
        if (!userOpt.get().isOwner()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "仅 owner 可创建牧场");
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
        FarmDto farm = farmApplicationService.createFarm(tenantId, command, userId);
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
        Map<String, Object> data = Map.of(
                "items", List.of(),
                "page", 1,
                "pageSize", 0,
                "total", 0
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    @PostMapping("/farms/{farmId}/members")
    public ResponseEntity<ApiResponse<Map<String, Object>>> addMember(
            @PathVariable Long farmId,
            @RequestBody Map<String, String> body) {
        Map<String, Object> data = Map.of(
                "message", "member management not yet implemented",
                "phase", "stub"
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(data));
    }

    @DeleteMapping("/farms/{farmId}/members/{userId}")
    public ResponseEntity<ApiResponse<Void>> removeMember(
            @PathVariable Long farmId,
            @PathVariable Long userId) {
        return ResponseEntity.ok(ApiResponse.ok(null));
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
