package com.smartlivestock.shared.security;

import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * NIX-337 regression lock: an API-key request whose Long principal collides
 * with a must-change-password user id must pass the interceptor — password
 * rotation is a user-session concept and the attribute is the discriminator.
 * A JWT user session with must_change_password must still be locked.
 */
@ExtendWith(MockitoExtension.class)
class PasswordChangeRequiredInterceptorTest {

    @Mock
    private UserRepository userRepository;

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void authAs(Long principalId) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principalId, null));
    }

    private User mustChangeUser() {
        // User has no setters for id/mustChangePassword; reconstitute via the
        // persistence constructor + reconstituteMustChangePassword.
        User user = new User("hash", "locked-user", null, null, true);
        return user;
    }

    @Test
    void apiKeyRequest_passesEvenWhenPrincipalCollidesWithLockedUser() {
        // api_keys.id = 5 happens to equal users.id = 5 with
        // must_change_password=TRUE — before the fix every call of that key
        // was 403 PASSWORD_CHANGE_REQUIRED.
        authAs(5L);
        // No user stubbing on purpose: the guard must short-circuit BEFORE
        // any user lookup (verified below with verify(..., never())).
        PasswordChangeRequiredInterceptor interceptor =
                new PasswordChangeRequiredInterceptor(userRepository);

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/open/farms/1/livestock/2");
        request.setAttribute(ApiKeyAuthFilter.ATTR_API_KEY, new Object());
        MockHttpServletResponse response = new MockHttpServletResponse();

        assertThat(interceptor.preHandle(request, response, new Object())).isTrue();
        // The guard must short-circuit BEFORE the user lookup — even though
        // the principal id collides with a locked user, no lookup happens.
        verify(userRepository, never()).findById(anyLong());
    }

    @Test
    void jwtUserWithMustChangePassword_stillLocked() {
        authAs(7L);
        when(userRepository.findById(7L)).thenReturn(Optional.of(mustChangeUser()));
        PasswordChangeRequiredInterceptor interceptor =
                new PasswordChangeRequiredInterceptor(userRepository);

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/farms/1/ranch-overview");
        MockHttpServletResponse response = new MockHttpServletResponse();

        assertThatCode(() -> interceptor.preHandle(request, response, new Object()))
                .isInstanceOf(ApiException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.PASSWORD_CHANGE_REQUIRED);
    }
}
