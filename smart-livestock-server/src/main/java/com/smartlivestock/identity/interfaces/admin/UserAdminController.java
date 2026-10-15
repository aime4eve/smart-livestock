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
                    Map<String, Object> item = new java.util.LinkedHashMap<>();
                    item.put("id", String.valueOf(u.getId()));
                    item.put("name", u.getName() != null ? u.getName() : "");
                    item.put("username", u.getUsername() != null ? u.getUsername() : "");
                    item.put("account", u.getAccount() != null ? u.getAccount() : "");
                    item.put("email", u.getEmail() != null ? u.getEmail() : "");
                    item.put("phone", u.getPhone() != null ? u.getPhone() : "");
                    item.put("role", u.getRole() != null ? u.getRole().toLowerCase() : "");
                    item.put("tenantId", u.getTenantId() != null ? String.valueOf(u.getTenantId()) : "");
                    item.put("tenantName", tenantName);
                    item.put("status", Boolean.TRUE.equals(u.getIsActive()) ? "active" : "disabled");
                    item.put("farmCount", farmCount);
                    item.put("lastLoginAt", u.getLastLoginAt() != null ? u.getLastLoginAt().toString() : "");
                    return item;
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
        String account = (String) body.get("account");
        String username = (String) body.get("username");
        String email = (String) body.get("email");
        String name = (String) body.get("name");
        String roleStr = (String) body.get("role");
        String password = (String) body.get("password");
        Object tenantIdObj = body.get("tenantId");

        if (name == null || name.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "name 不能为空");
        }
        if (roleStr == null || roleStr.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "role 不能为空");
        }
        // Login identifiers (ruling 2026-10-12): account / phone / email,
        // at least one; each globally unique when present.
        String normAccount = com.smartlivestock.identity.application.LoginIdentifiers.normalizeAccount(account);
        String normEmail = com.smartlivestock.identity.application.LoginIdentifiers.normalizeEmail(email);
        String normPhone = com.smartlivestock.identity.application.LoginIdentifiers.normalizePhone(phone);
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
            password = "Default@123!";
        }
        if (com.smartlivestock.shared.common.PasswordPolicy.violationKey(password) != null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, com.smartlivestock.shared.common.PasswordPolicy.WEAK_KEY);
        }

        User user = new User(passwordHasher.hash(password), name, role, tenantId, true);
        user.setPhone(normPhone);
        user.setAccount(normAccount);
        user.setUsername(username != null && !username.isBlank() ? username.trim() : null);
        user.setEmail(normEmail);
        User saved = userRepository.save(user);

        Map<String, Object> data = new java.util.LinkedHashMap<>();
        data.put("id", String.valueOf(saved.getId()));
        data.put("name", saved.getName());
        data.put("account", saved.getAccount() != null ? saved.getAccount() : "");
        data.put("username", saved.getUsername() != null ? saved.getUsername() : "");
        data.put("email", saved.getEmail() != null ? saved.getEmail() : "");
        data.put("phone", saved.getPhone() != null ? saved.getPhone() : "");
        data.put("role", saved.getRole().name().toLowerCase());
        data.put("tenantId", saved.getTenantId() != null ? String.valueOf(saved.getTenantId()) : "");
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

        Map<String, Object> data = new java.util.LinkedHashMap<>();
        data.put("id", String.valueOf(u.getId()));
        data.put("name", u.getName() != null ? u.getName() : "");
        data.put("username", u.getUsername() != null ? u.getUsername() : "");
        data.put("account", u.getAccount() != null ? u.getAccount() : "");
        data.put("email", u.getEmail() != null ? u.getEmail() : "");
        data.put("phone", u.getPhone() != null ? u.getPhone() : "");
        data.put("role", u.getRole() != null ? u.getRole().toLowerCase() : "");
        data.put("tenantId", u.getTenantId() != null ? String.valueOf(u.getTenantId()) : "");
        data.put("status", Boolean.TRUE.equals(u.getIsActive()) ? "active" : "disabled");
        data.put("farms", farms);
        data.put("lastLoginAt", u.getLastLoginAt() != null ? u.getLastLoginAt().toString() : "");
        data.put("createdAt", u.getCreatedAt() != null ? u.getCreatedAt().toString() : "");
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
        if (body.containsKey("username")) {
            String username = (String) body.get("username");
            user.setUsername(username == null || username.isBlank() ? null : username.trim());
        }
        if (body.containsKey("phone")) {
            String normPhone = com.smartlivestock.identity.application.LoginIdentifiers.normalizePhone((String) body.get("phone"));
            if (normPhone != null && !normPhone.equals(user.getPhone())) {
                if (!com.smartlivestock.identity.application.LoginIdentifiers.isValidPhone(normPhone)) {
                    throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.invalidPhone");
                }
                for (var existing : userRepository.findAll()) {
                    if (!existing.getId().equals(user.getId()) && normPhone.equals(existing.getPhone())) {
                        throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "user.phoneDuplicate");
                    }
                }
            }
            user.setPhone(normPhone);
        }
        if (body.containsKey("account")) {
            String normAccount = com.smartlivestock.identity.application.LoginIdentifiers.normalizeAccount((String) body.get("account"));
            if (normAccount != null && !normAccount.equalsIgnoreCase(user.getAccount())) {
                if (!com.smartlivestock.identity.application.LoginIdentifiers.isValidAccount(normAccount)) {
                    throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.invalidAccount");
                }
                for (var existing : userRepository.findAll()) {
                    if (!existing.getId().equals(user.getId()) && normAccount.equalsIgnoreCase(existing.getAccount())) {
                        throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "user.accountDuplicate");
                    }
                }
            }
            user.setAccount(normAccount);
        }
        if (body.containsKey("email")) {
            String normEmail = com.smartlivestock.identity.application.LoginIdentifiers.normalizeEmail((String) body.get("email"));
            if (normEmail != null && !normEmail.equalsIgnoreCase(user.getEmail())) {
                if (!com.smartlivestock.identity.application.LoginIdentifiers.isValidEmail(normEmail)) {
                    throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.invalidEmail");
                }
                for (var existing : userRepository.findAll()) {
                    if (!existing.getId().equals(user.getId()) && normEmail.equalsIgnoreCase(existing.getEmail())) {
                        throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "user.emailDuplicate");
                    }
                }
            }
            user.setEmail(normEmail);
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

        Map<String, Object> data = new java.util.LinkedHashMap<>();
        data.put("id", String.valueOf(saved.getId()));
        data.put("name", saved.getName() != null ? saved.getName() : "");
        data.put("username", saved.getUsername() != null ? saved.getUsername() : "");
        data.put("account", saved.getAccount() != null ? saved.getAccount() : "");
        data.put("email", saved.getEmail() != null ? saved.getEmail() : "");
        data.put("phone", saved.getPhone() != null ? saved.getPhone() : "");
        data.put("role", saved.getRole().name().toLowerCase());
        data.put("tenantId", saved.getTenantId() != null ? String.valueOf(saved.getTenantId()) : "");
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
        if (com.smartlivestock.shared.common.PasswordPolicy.violationKey(newPassword) != null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, com.smartlivestock.shared.common.PasswordPolicy.WEAK_KEY);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在: " + userId));
        // NIX-191: an operator-set reset password is again "someone else's"
        // credential — re-arm the forced password change.
        user.reconstituteMustChangePassword(true);

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
