package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.PasswordHasher;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class OwnerWorkerController {

    private final UserRepository userRepository;
    private final UserFarmAssignmentRepository userFarmAssignmentRepository;
    private final PasswordHasher passwordHasher;

    @PostMapping("/farms/{farmId}/workers")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createWorker(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        Long tenantId = requireTenantId();

        String phone = (String) body.get("phone");
        String name = (String) body.get("name");
        String password = (String) body.get("password");

        if (phone == null || phone.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "手机号不能为空");
        }
        if (name == null || name.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "姓名不能为空");
        }
        if (password == null || password.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "密码不能为空");
        }

        if (userRepository.findByPhone(phone).isPresent()) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "该手机号已注册");
        }

        User user = new User(passwordHasher.hash(password), name, Role.WORKER, tenantId);
        user.setPhone(phone);
        User saved = userRepository.save(user);

        if (!userFarmAssignmentRepository.existsByUserIdAndFarmId(saved.getId(), farmId)) {
            userFarmAssignmentRepository.save(saved.getId(), farmId, "WORKER", "ACTIVE");
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", String.valueOf(saved.getId()));
        data.put("name", saved.getName());
        data.put("phone", saved.getPhone());
        data.put("role", "worker");
        data.put("status", "active");
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(data));
    }

    @PutMapping("/farms/{farmId}/workers/{userId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateWorker(
            @PathVariable Long farmId,
            @PathVariable Long userId,
            @RequestBody Map<String, Object> body) {
        Long tenantId = requireTenantId();

        User user = findTenantWorker(userId, tenantId);

        if (body.get("name") != null) {
            String newName = (String) body.get("name");
            if (!newName.isBlank()) user.setName(newName);
        }
        if (body.get("phone") != null) {
            user.setPhone((String) body.get("phone"));
        }
        userRepository.save(user);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", String.valueOf(user.getId()));
        data.put("name", user.getName());
        data.put("phone", user.getPhone());
        data.put("role", "worker");
        data.put("status", user.isActive() ? "active" : "disabled");
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    @PutMapping("/farms/{farmId}/workers/{userId}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateWorkerStatus(
            @PathVariable Long farmId,
            @PathVariable Long userId,
            @RequestBody Map<String, Object> body) {
        Long tenantId = requireTenantId();

        User user = findTenantWorker(userId, tenantId);

        String status = (String) body.get("status");
        if (status == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "status 不能为空");
        }
        switch (status.toLowerCase()) {
            case "disabled" -> user.deactivate();
            case "active" -> user.activate();
            default -> throw new ApiException(ErrorCode.VALIDATION_ERROR, "无效的 status: " + status);
        }
        userRepository.save(user);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", String.valueOf(user.getId()));
        data.put("status", user.isActive() ? "active" : "disabled");
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    @PutMapping("/farms/{farmId}/workers/{userId}/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetWorkerPassword(
            @PathVariable Long farmId,
            @PathVariable Long userId,
            @RequestBody Map<String, Object> body) {
        Long tenantId = requireTenantId();

        User user = findTenantWorker(userId, tenantId);

        String newPassword = (String) body.get("password");
        if (newPassword == null || newPassword.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "密码不能为空");
        }
        user.setPasswordHash(passwordHasher.hash(newPassword));
        userRepository.save(user);

        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    // ── Helpers ─────────────────────────────────────────────────

    private Long requireTenantId() {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证或缺少租户信息");
        }
        return tenantId;
    }

    private User findTenantWorker(Long userId, Long tenantId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在: " + userId));
        if (!tenantId.equals(user.getTenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权操作该用户");
        }
        return user;
    }
}
