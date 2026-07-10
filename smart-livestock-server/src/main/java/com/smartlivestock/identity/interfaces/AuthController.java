package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.application.AuthApplicationService;
import com.smartlivestock.identity.application.command.LoginCommand;
import com.smartlivestock.identity.application.dto.AuthTokenDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthApplicationService authApplicationService;

    /**
     * POST /api/v1/auth/login
     * Login with phone + password, returns JWT token.
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthTokenDto>> login(@RequestBody LoginCommand command) {
        AuthTokenDto result = authApplicationService.login(command);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    /**
     * POST /api/v1/auth/refresh
     * Refresh access token. Accepts a valid or recently-expired access token,
     * returns a new access token with fresh expiration.
     */
    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthTokenDto>> refresh(@RequestBody Map<String, String> body) {
        String currentToken = body.get("accessToken");
        if (currentToken == null || currentToken.isBlank()) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "缺少 accessToken");
        }
        AuthTokenDto result = authApplicationService.refresh(currentToken);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    /**
     * POST /api/v1/auth/logout
     * Logout. Stateless JWT — client discards the token.
     * Returns OK regardless; the client-side token clearing is the actual logout.
     */
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout() {
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
