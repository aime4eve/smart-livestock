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

        String name = (String) body.get("name");
        String password = (String) body.get("password");
        String account = (String) body.get("account");
        String username = (String) body.get("username");
        String email = (String) body.get("email");

        if (name == null || name.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "姓名不能为空");
        }
        if (password == null || password.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "密码不能为空");
        }
        String normAccount = com.smartlivestock.identity.application.LoginIdentifiers.normalizeAccount(account);
        String normEmail = com.smartlivestock.identity.application.LoginIdentifiers.normalizeEmail(email);
        String normPhone = com.smartlivestock.identity.application.LoginIdentifiers.normalizePhone((String) body.get("phone"));
        if (normAccount == null && normEmail == null && normPhone == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.identifierRequired");
        }
        if (normAccount != null && !com.smartlivestock.identity.application.LoginIdentifiers.isValidAccount(normAccount)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.invalidAccount");
        }
        if (normEmail != null && !com.smartlivestock.identity.application.LoginIdentifiers.isValidEmail(normEmail)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.invalidEmail");
        }
        if (normPhone != null && !com.smartlivestock.identity.application.LoginIdentifiers.isValidPhone(normPhone)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.invalidPhone");
        }
        for (var existing : userRepository.findAll()) {
            if (normAccount != null && normAccount.equalsIgnoreCase(existing.getAccount())) {
                throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "user.accountDuplicate");
            }
            if (normEmail != null && normEmail.equalsIgnoreCase(existing.getEmail())) {
                throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "user.emailDuplicate");
            }
            if (normPhone != null && normPhone.equals(existing.getPhone())) {
                throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "user.phoneDuplicate");
            }
        }

        User user = new User(passwordHasher.hash(password), name, Role.WORKER, tenantId);
        user.setPhone(normPhone);
        user.setAccount(normAccount);
        user.setEmail(normEmail);
        user.setUsername(username == null || username.isBlank() ? null : username.trim());
        User saved = userRepository.save(user);

        if (!userFarmAssignmentRepository.existsByUserIdAndFarmId(saved.getId(), farmId)) {
            userFarmAssignmentRepository.save(saved.getId(), farmId, "WORKER", "ACTIVE");
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", String.valueOf(saved.getId()));
        data.put("name", saved.getName());
        data.put("username", saved.getUsername() != null ? saved.getUsername() : "");
        data.put("account", saved.getAccount() != null ? saved.getAccount() : "");
        data.put("email", saved.getEmail() != null ? saved.getEmail() : "");
        data.put("phone", saved.getPhone() != null ? saved.getPhone() : "");
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
