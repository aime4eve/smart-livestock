package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.application.AuthApplicationService;
import com.smartlivestock.identity.application.command.LoginCommand;
import com.smartlivestock.identity.application.command.SwitchContextCommand;
import com.smartlivestock.identity.application.dto.AuthTokenDto;
import com.smartlivestock.identity.application.dto.EntryContextsDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthApplicationService authApplicationService;

    /**
     * POST /api/v1/auth/login
     * Login with account / phone (E.164) / email + password, returns JWT token.
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthTokenDto>> login(@RequestBody LoginCommand command) {
        AuthTokenDto result = authApplicationService.login(command);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    /**
     * GET /api/v1/auth/entry-contexts
     * Super-admin picker data: selectable entry roles + tenant options
     * (design 2026-10-19 §4.3). Root SUPER_ADMIN token only.
     */
    @GetMapping("/entry-contexts")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<EntryContextsDto>> entryContexts() {
        return ResponseEntity.ok(ApiResponse.ok(authApplicationService.listEntryContexts()));
    }

    /**
     * POST /api/v1/auth/switch-context
     * Issue a context token for the chosen role/tenant (super-admin role
     * entry, design §4.2/§4.3). Root SUPER_ADMIN token only; a context
     * token itself cannot call this again (anti escalation).
     */
    @PostMapping("/switch-context")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<AuthTokenDto>> switchContext(@RequestBody SwitchContextCommand command) {
        return ResponseEntity.ok(ApiResponse.ok(
                authApplicationService.switchContext(getCurrentUserId(), command)));
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

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        return (Long) authentication.getPrincipal();
    }
}
