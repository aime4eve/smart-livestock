package com.smartlivestock.identity.application.service;

import com.smartlivestock.identity.application.AuthApplicationService;
import com.smartlivestock.identity.application.command.LoginCommand;
import com.smartlivestock.identity.application.dto.AuthTokenDto;
import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.JwtTokenProvider;
import com.smartlivestock.shared.security.PasswordHasher;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit-level integration test for AuthApplicationService.
 * <p>
 * Tests the login flow with mocked dependencies to verify authentication
 * business logic without Spring context.
 */
@ExtendWith(MockitoExtension.class)
class AuthApplicationServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordHasher passwordHasher;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @InjectMocks
    private AuthApplicationService service;

    private User createActiveUser() {
        User user = new User("owner1", "hashed_password", "张三", Role.OWNER, 1L);
        user.setId(1L);
        user.setPhone("13800138000");
        return user;
    }

    @Test
    @DisplayName("正常登录成功，返回 JWT token 和用户信息")
    void shouldLoginSuccessfully() {
        User user = createActiveUser();
        when(userRepository.findByPhone("13800138000")).thenReturn(Optional.of(user));
        when(passwordHasher.matches("password123", "hashed_password")).thenReturn(true);
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtTokenProvider.generateToken(1L, 1L, "OWNER")).thenReturn("jwt-token-owner");

        AuthTokenDto result = service.login(new LoginCommand("13800138000", "password123"));

        assertThat(result.token()).isEqualTo("jwt-token-owner");
        assertThat(result.user().username()).isEqualTo("owner1");
        assertThat(result.user().role()).isEqualTo("OWNER");
        assertThat(result.user().tenantId()).isEqualTo(1L);

        verify(userRepository).save(any(User.class)); // recordLogin persists
    }

    @Test
    @DisplayName("密码错误时，拒绝登录")
    void shouldRejectWrongPassword() {
        User user = createActiveUser();
        when(userRepository.findByPhone("13800138000")).thenReturn(Optional.of(user));
        when(passwordHasher.matches("wrong_password", "hashed_password")).thenReturn(false);

        assertThatThrownBy(() -> service.login(new LoginCommand("13800138000", "wrong_password")))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.AUTH_INVALID_TOKEN);
                });

        verify(jwtTokenProvider, never()).generateToken(any(), any(), any());
    }

    @Test
    @DisplayName("已停用的用户，拒绝登录")
    void shouldRejectInactiveUser() {
        User user = createActiveUser();
        user.reconstituteActive(false);

        when(userRepository.findByPhone("13800138000")).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.login(new LoginCommand("13800138000", "password123")))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.AUTH_FORBIDDEN);
                });

        verify(passwordHasher, never()).matches(any(), any());
        verify(jwtTokenProvider, never()).generateToken(any(), any(), any());
    }

    @Test
    @DisplayName("手机号不存在时，拒绝登录")
    void shouldRejectNonExistentPhone() {
        when(userRepository.findByPhone("19999999999")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.login(new LoginCommand("19999999999", "password123")))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.AUTH_INVALID_TOKEN);
                });

        verify(passwordHasher, never()).matches(any(), any());
        verify(jwtTokenProvider, never()).generateToken(any(), any(), any());
    }
}
