package com.smartlivestock.identity.interfaces;

import com.smartlivestock.identity.application.FarmApplicationService;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * createFarm authorization must follow token authorities, not the stored
 * user row (design 2026-10-19 §4.5): a super-admin OWNER context token
 * (role claim OWNER, sub = super admin) passes exactly like a real owner,
 * with zero DB user-row loads; the root SUPER_ADMIN token is refused like
 * any other non-creator role.
 */
class FarmControllerCreateFarmTest {

    private final FarmApplicationService farmApplicationService = mock(FarmApplicationService.class);
    private final UserRepository userRepository = mock(UserRepository.class);
    private final UserFarmAssignmentRepository assignmentRepository = mock(UserFarmAssignmentRepository.class);

    private final FarmController controller =
            new FarmController(farmApplicationService, userRepository, assignmentRepository);

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        TenantContext.clear();
    }

    private void authenticateAs(String... authorities) {
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                6L, "creds",
                Arrays.stream(authorities).map(SimpleGrantedAuthority::new).toList()));
    }

    @Test
    void ownerContextToken_passesWithoutUserRowLoad() {
        authenticateAs("ROLE_OWNER");
        TenantContext.setCurrentTenant(2L);
        when(farmApplicationService.listFarms(2L)).thenReturn(List.of());
        when(farmApplicationService.createFarm(eq(2L), any(), eq(6L))).thenReturn(mock(FarmDto.class));

        var response = controller.createFarm(Map.of("name", "支持排障牧场"));

        assertThat(response.getStatusCode().value()).isEqualTo(201);
        // The decisive regression: authorization never consults the stored row.
        verify(userRepository, never()).findById(any());
    }

    @Test
    void workerContextToken_refused() {
        authenticateAs("ROLE_WORKER");
        TenantContext.setCurrentTenant(2L);

        assertThatThrownBy(() -> controller.createFarm(Map.of("name", "x")))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.AUTH_FORBIDDEN));
    }

    @Test
    void rootSuperAdminToken_refused_outsideAnyContext() {
        authenticateAs("ROLE_SUPER_ADMIN");
        TenantContext.setCurrentTenant(null);

        assertThatThrownBy(() -> controller.createFarm(Map.of("name", "x")))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode()).isEqualTo(ErrorCode.AUTH_FORBIDDEN));
    }
}
