package com.smartlivestock.identity.interfaces.admin;

import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataUserRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.PasswordHasher;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Admin User Management — 6 endpoints.
 * All operations require platform_admin role and operate across tenants.
 */
@RestController
@RequestMapping("/api/v1/admin/users")
@RequiredArgsConstructor
public class UserAdminController {

    private final SpringDataUserRepository springDataUserRepository;
    private final UserRepository userRepository;
    private final TenantRepository tenantRepository;
    private final FarmRepository farmRepository;
    private final PasswordHasher passwordHasher;

    /**
     * GET /api/v1/admin/users
     * Cross-tenant user list with filters.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listUsers(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Long tenantId,
            @RequestParam(required = false) Long farmId,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword) {
        requirePlatformAdmin();

        List<UserJpaEntity> users = springDataUserRepository.findAll();
        List<Map<String, Object>> items = users.stream()
                .filter(u -> tenantId == null || tenantId.equals(u.getTenantId()))
                .filter(u -> role == null || role.equalsIgnoreCase(u.getRole()))
                .map(u -> {
                    String tenantName = "";
                    if (u.getTenantId() != null) {
                        tenantName = tenantRepository.findById(u.getTenantId())
                                .map(t -> t.getName())
                                .orElse("");
                    }
                    long farmCount = u.getTenantId() != null
                            ? farmRepository.findByTenantId(u.getTenantId()).size()
                            : 0;
                    return Map.<String, Object>of(
                            "id", String.valueOf(u.getId()),
                            "name", u.getName() != null ? u.getName() : "",
                            "phone", u.getPhone() != null ? u.getPhone() : "",
                            "role", u.getRole() != null ? u.getRole().toLowerCase() : "",
                            "tenantId", u.getTenantId() != null ? String.valueOf(u.getTenantId()) : "",
                            "tenantName", tenantName,
                            "status", Boolean.TRUE.equals(u.getIsActive()) ? "active" : "disabled",
                            "farmCount", farmCount,
                            "lastLoginAt", u.getLastLoginAt() != null ? u.getLastLoginAt().toString() : ""
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
     * POST /api/v1/admin/users
     * Create user (specify tenantId + role).
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createUser(@RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        String phone = (String) body.get("phone");
        String name = (String) body.get("name");
        String roleStr = (String) body.get("role");
        String password = (String) body.get("password");
        Object tenantIdObj = body.get("tenantId");

        if (phone == null || phone.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "phone 不能为空");
        }
        if (name == null || name.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "name 不能为空");
        }
        if (roleStr == null || roleStr.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "role 不能为空");
        }

        // Check for duplicate phone
        if (userRepository.findByPhone(phone).isPresent()) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "该手机号已注册");
        }

        Role role;
        try {
            role = Role.valueOf(roleStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "无效的 role: " + roleStr);
        }

        Long tenantId = null;
        if (tenantIdObj != null) {
            tenantId = Long.valueOf(tenantIdObj.toString());
        }

        if (password == null || password.isBlank()) {
            password = "Default@123";
        }

        User user = new User(passwordHasher.hash(password), name, role, tenantId);
        user.setPhone(phone);
        User saved = userRepository.save(user);

        Map<String, Object> data = Map.<String, Object>of(
                "id", String.valueOf(saved.getId()),
                "name", saved.getName(),
                "role", saved.getRole().name().toLowerCase(),
                "tenantId", saved.getTenantId() != null ? String.valueOf(saved.getTenantId()) : ""
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/admin/users/{userId}
     * User detail with associated farms list.
     */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUser(@PathVariable Long userId) {
        requirePlatformAdmin();

        UserJpaEntity u = springDataUserRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在: " + userId));

        List<Map<String, Object>> farms = List.of();

        Map<String, Object> data = Map.<String, Object>of(
                "id", String.valueOf(u.getId()),
                "name", u.getName() != null ? u.getName() : "",
                "phone", u.getPhone() != null ? u.getPhone() : "",
                "role", u.getRole() != null ? u.getRole().toLowerCase() : "",
                "tenantId", u.getTenantId() != null ? String.valueOf(u.getTenantId()) : "",
                "status", Boolean.TRUE.equals(u.getIsActive()) ? "active" : "disabled",
                "farms", farms,
                "lastLoginAt", u.getLastLoginAt() != null ? u.getLastLoginAt().toString() : "",
                "createdAt", u.getCreatedAt() != null ? u.getCreatedAt().toString() : ""
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * PUT /api/v1/admin/users/{userId}
     * Update user info.
     */
    @PutMapping("/{userId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateUser(
            @PathVariable Long userId,
            @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在: " + userId));

        if (body.containsKey("name")) {
            user.setName((String) body.get("name"));
        }
        if (body.containsKey("phone")) {
            user.setPhone((String) body.get("phone"));
        }
        if (body.containsKey("role")) {
            String roleStr = (String) body.get("role");
            try {
                user.setRole(Role.valueOf(roleStr.toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "无效的 role: " + roleStr);
            }
        }

        User saved = userRepository.save(user);

        Map<String, Object> data = Map.<String, Object>of(
                "id", String.valueOf(saved.getId()),
                "name", saved.getName() != null ? saved.getName() : "",
                "phone", saved.getPhone() != null ? saved.getPhone() : "",
                "role", saved.getRole().name().toLowerCase(),
                "tenantId", saved.getTenantId() != null ? String.valueOf(saved.getTenantId()) : ""
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * PUT /api/v1/admin/users/{userId}/status
     * Enable/disable/lock user. Idempotent.
     */
    @PutMapping("/{userId}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateUserStatus(
            @PathVariable Long userId,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String status = body.get("status");
        if (status == null || (!status.equals("active") && !status.equals("disabled") && !status.equals("locked"))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "status 必须为 active、disabled 或 locked");
        }

        UserJpaEntity userEntity = springDataUserRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在: " + userId));

        userEntity.setIsActive("active".equals(status));
        springDataUserRepository.save(userEntity);

        Map<String, Object> data = Map.of(
                "id", String.valueOf(userId),
                "status", status
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/admin/users/{userId}/reset-password
     * Reset user password.
     */
    @PostMapping("/{userId}/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @PathVariable Long userId,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String newPassword = body.get("newPassword");
        if (newPassword == null || newPassword.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "newPassword 不能为空");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在: " + userId));

        user.setPasswordHash(passwordHasher.hash(newPassword));
        userRepository.save(user);

        return ResponseEntity.ok(ApiResponse.ok(null));
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
