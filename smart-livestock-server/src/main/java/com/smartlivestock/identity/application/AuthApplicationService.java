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

    @Transactional(readOnly = true)
    public AuthTokenDto login(LoginCommand command) {
        User user = userRepository.findByPhone(command.phone())
                .orElseThrow(() -> new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "手机号或密码错误"));
        if (!user.isActive()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "用户已停用");
        }
        if (!passwordHasher.matches(command.password(), user.getPasswordHash())) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "手机号或密码错误");
        }
        user.recordLogin();
        userRepository.save(user);
        String token = jwtTokenProvider.generateToken(user.getId(), user.getTenantId(), user.getRole().name());
        return new AuthTokenDto(token, UserDto.from(user));
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
