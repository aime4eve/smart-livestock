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
     * Update current user info (name, phone).
     * Phone changes require the current password for confirmation — the phone
     * number is the login identity, so it must not be swapable by an XSS-ed
     * or borrowed session (NIX-191).
     */
    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserDto>> updateCurrentUser(@RequestBody Map<String, String> body) {
        Long userId = getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在"));

        if (body.containsKey("name")) {
            user.setName(body.get("name"));
        }
        if (body.containsKey("phone")) {
            String newPhone = body.get("phone");
            if (newPhone == null || newPhone.isBlank()) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.phoneChangeRequiresPassword");
            }
            if (!newPhone.equals(user.getPhone())) {
                String currentPassword = body.get("currentPassword");
                if (currentPassword == null
                        || !passwordHasher.matches(currentPassword, user.getPasswordHash())) {
                    throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.phoneChangeRequiresPassword");
                }
                userRepository.findByPhone(newPhone)
                        .filter(other -> !other.getId().equals(userId))
                        .ifPresent(other -> {
                            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.phoneAlreadyUsed");
                        });
                user.setPhone(newPhone);
            }
        }

        User saved = userRepository.save(user);
        return ResponseEntity.ok(ApiResponse.ok(UserDto.from(saved)));
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
        return password.length() >= 10
                && password.chars().anyMatch(Character::isLetter)
                && password.chars().anyMatch(Character::isDigit);
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        return (Long) authentication.getPrincipal();
    }
}
