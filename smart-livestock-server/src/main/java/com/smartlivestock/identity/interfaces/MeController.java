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
            user.setPhone(body.get("phone"));
        }

        User saved = userRepository.save(user);
        return ResponseEntity.ok(ApiResponse.ok(UserDto.from(saved)));
    }

    /**
     * PUT /api/v1/me/password
     * Change password.
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

        user.setPasswordHash(passwordHasher.hash(newPassword));
        userRepository.save(user);

        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        return (Long) authentication.getPrincipal();
    }
}
