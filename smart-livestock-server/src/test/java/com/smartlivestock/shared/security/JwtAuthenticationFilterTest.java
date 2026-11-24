package com.smartlivestock.shared.security;

import com.smartlivestock.shared.tenant.TenantContext;
import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The filter must tell a super-admin switched-context token (act claim) apart
 * from a plain one by flagging the Authentication it builds; everything else
 * about the request identity stays as before.
 */
class JwtAuthenticationFilterTest {

    private static final Map<String, Object> SUPER_ADMIN_ACT = Map.of("sub", 9L, "role", "SUPER_ADMIN");

    private final JwtTokenProvider provider =
            new JwtTokenProvider("unit-test-secret-0123456789abcdef0123456789abcdef", 3600000L);
    private final JwtAuthenticationFilter filter = new JwtAuthenticationFilter(provider);

    /** What downstream code observes while the request is inside the chain. */
    private record RequestIdentity(
            Long principal,
            String authority,
            Object details,
            boolean switchedContext,
            Long tenantId
    ) {
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        TenantContext.clear();
    }

    @Test
    void switchedContextToken_isFlaggedOnTheAuthentication() throws Exception {
        String token = provider.generateToken(9L, 1L, "OWNER", SUPER_ADMIN_ACT);

        RequestIdentity identity = passThrough(token);

        assertThat(identity.principal()).isEqualTo(9L);
        assertThat(identity.authority()).isEqualTo("ROLE_OWNER");
        assertThat(identity.tenantId()).isEqualTo(1L);
        assertThat(identity.details()).isEqualTo(new SwitchedContext.Marker(9L));
        assertThat(identity.switchedContext()).isTrue();
    }

    @Test
    void plainToken_carriesNoMarker() throws Exception {
        RequestIdentity identity = passThrough(provider.generateToken(2L, 1L, "OWNER"));

        assertThat(identity.principal()).isEqualTo(2L);
        assertThat(identity.authority()).isEqualTo("ROLE_OWNER");
        assertThat(identity.details()).isNull();
        assertThat(identity.switchedContext()).isFalse();
    }

    @Test
    void rootSuperAdminToken_carriesNoMarker() throws Exception {
        RequestIdentity identity = passThrough(provider.generateToken(9L, null, "SUPER_ADMIN"));

        assertThat(identity.principal()).isEqualTo(9L);
        assertThat(identity.authority()).isEqualTo("ROLE_SUPER_ADMIN");
        assertThat(identity.details()).isNull();
        assertThat(identity.switchedContext()).isFalse();
    }

    @Test
    void missingToken_leavesTheRequestAnonymous() throws Exception {
        RequestIdentity identity = passThrough(null);

        assertThat(identity.principal()).isNull();
        assertThat(identity.authority()).isNull();
        assertThat(identity.switchedContext()).isFalse();
        assertThat(identity.tenantId()).isNull();
    }

    @Test
    void tamperedToken_leavesTheRequestAnonymous() throws Exception {
        String token = provider.generateToken(9L, 1L, "OWNER", SUPER_ADMIN_ACT);

        RequestIdentity identity = passThrough(token.substring(0, token.length() - 3) + "xyz");

        assertThat(identity.principal()).isNull();
        assertThat(identity.switchedContext()).isFalse();
        assertThat(identity.tenantId()).isNull();
    }

    @Test
    void tenantContextIsClearedAfterTheRequest() throws Exception {
        passThrough(provider.generateToken(9L, 1L, "OWNER", SUPER_ADMIN_ACT));

        assertThat(TenantContext.getCurrentTenant()).isNull();
    }

    private RequestIdentity passThrough(String bearerToken) throws Exception {
        SecurityContextHolder.clearContext();
        TenantContext.clear();
        MockHttpServletRequest request = new MockHttpServletRequest();
        if (bearerToken != null) {
            request.addHeader("Authorization", "Bearer " + bearerToken);
        }
        AtomicReference<RequestIdentity> seen = new AtomicReference<>();
        FilterChain chain = (req, res) -> {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            seen.set(new RequestIdentity(
                    authentication != null && authentication.getPrincipal() instanceof Long id ? id : null,
                    authentication != null
                            ? authentication.getAuthorities().iterator().next().getAuthority()
                            : null,
                    authentication != null ? authentication.getDetails() : null,
                    SwitchedContext.isCurrent(),
                    TenantContext.getCurrentTenant()));
        };
        filter.doFilter(request, new MockHttpServletResponse(), chain);
        return seen.get();
    }
}
