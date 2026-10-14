package com.smartlivestock.identity.application;

import com.smartlivestock.identity.application.command.LoginCommand;
import com.smartlivestock.identity.application.dto.AuthTokenDto;
import com.smartlivestock.identity.application.dto.UserDto;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.JwtTokenProvider;
import com.smartlivestock.shared.security.PasswordHasher;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthApplicationService {

    private final UserRepository userRepository;
    private final PasswordHasher passwordHasher;
    private final JwtTokenProvider jwtTokenProvider;
    private final com.smartlivestock.identity.domain.repository.TenantRepository tenantRepository;

    @Transactional(readOnly = true)
    public AuthTokenDto login(LoginCommand command) {
        // Identifier routing (ruling 2026-10-12): email → phone (E.164 +
        // legacy bare-number fallback) → account. Message stays generic
        // ("账号或密码错误") so login probing learns nothing.
        User user = resolveLoginUser(command.identifier())
                .orElseThrow(() -> new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "auth.invalidIdentifierOrPassword"));
        if (!user.isActive()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "用户已停用");
        }
        // Tenant lifecycle gate (ruling 2026-10-14): disabled/deleted tenants
        // reject login for every member.
        if (user.getTenantId() != null) {
            tenantRepository.findById(user.getTenantId()).ifPresent(tenant -> {
                if (tenant.isDeleted()) {
                    throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "auth.tenantDeleted");
                }
                if ("disabled".equals(tenant.getStatus())) {
                    throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "auth.tenantDisabled");
                }
            });
        }
        if (!passwordHasher.matches(command.password(), user.getPasswordHash())) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "auth.invalidIdentifierOrPassword");
        }
        user.recordLogin();
        userRepository.save(user);
        String token = jwtTokenProvider.generateToken(user.getId(), user.getTenantId(), user.getRole().name());
        return new AuthTokenDto(token, UserDto.from(user));
    }

    /** Account / email are case-insensitive; phone tries E.164 first, then
     *  the raw string so legacy bare 11-digit numbers keep working. */
    private java.util.Optional<User> resolveLoginUser(String raw) {
        String v = raw == null ? "" : raw.trim();
        if (v.isEmpty()) return java.util.Optional.empty();
        switch (com.smartlivestock.identity.application.LoginIdentifiers.classify(v)) {
            case EMAIL: return userRepository.findByLoginIdentifier(
                    com.smartlivestock.identity.application.LoginIdentifiers.normalizeEmail(v));
            case PHONE: {
                java.util.Optional<User> e164 = userRepository.findByLoginIdentifier(
                        com.smartlivestock.identity.application.LoginIdentifiers.normalizePhone(v));
                if (e164.isPresent()) return e164;
                return userRepository.findByLoginIdentifier(v);
            }
            default: return userRepository.findByLoginIdentifier(
                    com.smartlivestock.identity.application.LoginIdentifiers.normalizeAccount(v));
        }
    }

    /**
     * Refresh: validate current access token (grace period for recently expired),
     * look up user, and issue a new access token.
     */
    @Transactional(readOnly = true)
    public AuthTokenDto refresh(String currentToken) {
        String newToken = jwtTokenProvider.refreshToken(currentToken);
        if (newToken == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "Token 无法刷新，请重新登录");
        }
        Long userId = jwtTokenProvider.getUserIdFromToken(newToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "用户不存在"));
        if (!user.isActive()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "用户已停用");
        }
        return new AuthTokenDto(newToken, UserDto.from(user));
    }
}
