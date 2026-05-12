package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.application.AuthApplicationService;
import com.smartlivestock.identity.application.command.LoginCommand;
import com.smartlivestock.identity.application.dto.AuthTokenDto;
import com.smartlivestock.shared.common.ApiResponse;
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
     * Refresh token (Phase 1 stub).
     */
    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<Map<String, Object>>> refresh(@RequestBody Map<String, String> body) {
        // Phase 1 stub — refresh token rotation not yet implemented
        Map<String, Object> stub = Map.of(
                "message", "refresh not yet implemented",
                "phase", "stub"
        );
        return ResponseEntity.ok(ApiResponse.ok(stub));
    }

    /**
     * POST /api/v1/auth/logout
     * Logout (Phase 1 stub — revoke refresh token).
     */
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestBody(required = false) Map<String, String> body) {
        // Phase 1 stub — token revocation not yet implemented
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
