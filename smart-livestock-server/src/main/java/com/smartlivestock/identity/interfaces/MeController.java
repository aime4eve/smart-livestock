package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.application.dto.UserDto;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.PasswordHasher;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class MeController {

    private final UserRepository userRepository;
    private final PasswordHasher passwordHasher;
    private final com.smartlivestock.identity.domain.repository.AuditLogRepository auditLogRepository;

    /**
     * GET /api/v1/me
     * Get current user info.
     */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserDto>> getCurrentUser() {
        Long userId = getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在"));
        return ResponseEntity.ok(ApiResponse.ok(UserDto.from(user)));
    }

    /**
     * PUT /api/v1/me
     * Update current user info (name, username, phone, account, email).
     * Login identifiers (phone / account / email) require the current
     * password for confirmation — they are the login identity and must not
     * be swapable by an XSS-ed or borrowed session (NIX-191). The display
     * username changes freely.
     */
    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserDto>> updateCurrentUser(@RequestBody Map<String, String> body) {
        Long userId = getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在"));

        if (body.containsKey("name")) {
            user.setName(body.get("name"));
        }
        if (body.containsKey("username")) {
            String username = body.get("username");
            user.setUsername(username == null || username.isBlank() ? null : username.trim());
        }

        boolean identifierTouched = false;
        if (body.containsKey("phone")) {
            String norm = com.smartlivestock.identity.application.LoginIdentifiers.normalizePhone(body.get("phone"));
            if (norm != null && !norm.equals(user.getPhone())) identifierTouched = true;
            if (norm != null && !com.smartlivestock.identity.application.LoginIdentifiers.isValidPhone(norm)) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.invalidPhone");
            }
            if (norm != null && !norm.equals(user.getPhone())) {
                requireUnique(other -> norm.equals(other.getPhone()), "user.phoneDuplicate");
                user.setPhone(norm);
            } else if (norm == null) {
                user.setPhone(null);
            }
        }
        if (body.containsKey("account")) {
            String norm = com.smartlivestock.identity.application.LoginIdentifiers.normalizeAccount(body.get("account"));
            if (norm != null && !norm.equalsIgnoreCase(user.getAccount())) identifierTouched = true;
            if (norm != null && !com.smartlivestock.identity.application.LoginIdentifiers.isValidAccount(norm)) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.invalidAccount");
            }
            if (norm != null && !norm.equalsIgnoreCase(user.getAccount())) {
                requireUnique(other -> norm.equalsIgnoreCase(other.getAccount()), "user.accountDuplicate");
                user.setAccount(norm);
            } else if (norm == null) {
                user.setAccount(null);
            }
        }
        if (body.containsKey("email")) {
            String norm = com.smartlivestock.identity.application.LoginIdentifiers.normalizeEmail(body.get("email"));
            if (norm != null && !norm.equalsIgnoreCase(user.getEmail())) identifierTouched = true;
            if (norm != null && !com.smartlivestock.identity.application.LoginIdentifiers.isValidEmail(norm)) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.invalidEmail");
            }
            if (norm != null && !norm.equalsIgnoreCase(user.getEmail())) {
                requireUnique(other -> norm.equalsIgnoreCase(other.getEmail()), "user.emailDuplicate");
                user.setEmail(norm);
            } else if (norm == null) {
                user.setEmail(null);
            }
        }

        if (identifierTouched) {
            // At least one login identifier must remain after the change.
            if (user.getPhone() == null && user.getAccount() == null && user.getEmail() == null) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "user.identifierRequired");
            }
            String currentPassword = body.get("currentPassword");
            if (currentPassword == null
                    || !passwordHasher.matches(currentPassword, user.getPasswordHash())) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.phoneChangeRequiresPassword");
            }
        }

        User saved = userRepository.save(user);
        if (identifierTouched) {
            try {
                auditLogRepository.save(new com.smartlivestock.identity.domain.model.AuditLog(
                        java.util.UUID.randomUUID().toString(),
                        "USER_LOGIN_IDENTIFIER_CHANGED",
                        user.getTenantId(), userId, "USER_LOGIN_IDENTIFIER_CHANGED",
                        java.util.Map.of("userId", userId),
                        java.time.Instant.now(), null, user.getRole().name()));
            } catch (Exception ignored) {
                // audit best-effort
            }
        }
        return ResponseEntity.ok(ApiResponse.ok(UserDto.from(saved)));
    }

    private void requireUnique(java.util.function.Predicate<User> conflict, String messageKey) {
        userRepository.findAll().stream()
                .filter(conflict)
                .findFirst()
                .ifPresent(other -> {
                    throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, messageKey);
                });
    }

    /**
     * PUT /api/v1/me/password
     * Change password. Strength: >= 10 chars with letters and digits.
     * Clears must_change_password (NIX-191 forced password change).
     */
    @PutMapping("/me/password")
    public ResponseEntity<ApiResponse<Void>> changePassword(@RequestBody Map<String, String> body) {
        Long userId = getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在"));

        String oldPassword = body.get("oldPassword");
        String newPassword = body.get("newPassword");

        if (oldPassword == null || newPassword == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "oldPassword 和 newPassword 不能为空");
        }

        if (!passwordHasher.matches(oldPassword, user.getPasswordHash())) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "原密码错误");
        }

        if (!isStrongPassword(newPassword)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.passwordWeak");
        }

        user.setPasswordHash(passwordHasher.hash(newPassword));
        user.completePasswordChange();
        userRepository.save(user);

        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    private boolean isStrongPassword(String password) {
        return com.smartlivestock.shared.common.PasswordPolicy.isStrong(password);
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        return (Long) authentication.getPrincipal();
    }
}
