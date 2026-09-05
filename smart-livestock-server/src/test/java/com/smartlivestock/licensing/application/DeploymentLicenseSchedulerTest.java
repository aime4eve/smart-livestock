package com.smartlivestock.licensing.application;

import com.smartlivestock.licensing.domain.repository.DeploymentInstallationRepository;
import com.smartlivestock.licensing.infrastructure.config.LicenseProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the periodic validation trigger (NIX-184 T4b): HOSTED is a
 * no-op, ONPREM validates every tenant with per-tenant error isolation.
 */
@ExtendWith(MockitoExtension.class)
class DeploymentLicenseSchedulerTest {

    @Mock
    private DeploymentInstallationRepository installationRepository;
    @Mock
    private LicenseTimeGuardService timeGuardService;

    private LicenseProperties properties;

    @BeforeEach
    void setUp() {
        properties = new LicenseProperties();
    }

    private DeploymentLicenseScheduler createScheduler() {
        return new DeploymentLicenseScheduler(properties, installationRepository, timeGuardService);
    }

    @Nested
    class HostedMode {

        @Test
        void hostedMode_isNoOp() {
            properties.setMode(LicenseProperties.LicenseMode.HOSTED);

            createScheduler().validateAllTenants();

            verify(installationRepository, never()).findAllTenantIds();
            verify(timeGuardService, never()).validateTenant(anyLong());
        }
    }

    @Nested
    class OnPremMode {

        @BeforeEach
        void enableOnPrem() {
            properties.setMode(LicenseProperties.LicenseMode.ONPREM);
        }

        @Test
        void validatesEveryTenantWithInstallation() {
            when(installationRepository.findAllTenantIds()).thenReturn(List.of(1L, 2L, 3L));

            createScheduler().validateAllTenants();

            verify(timeGuardService).validateTenant(1L);
            verify(timeGuardService).validateTenant(2L);
            verify(timeGuardService).validateTenant(3L);
        }

        @Test
        void tenantFailureDoesNotBlockOthers() {
            when(installationRepository.findAllTenantIds()).thenReturn(List.of(1L, 2L));
            when(timeGuardService.validateTenant(1L))
                    .thenThrow(new IllegalStateException("db broken"));

            assertThatCode(createScheduler()::validateAllTenants).doesNotThrowAnyException();

            verify(timeGuardService).validateTenant(2L);
        }

        @Test
        void noInstallations_noValidation() {
            when(installationRepository.findAllTenantIds()).thenReturn(List.of());

            createScheduler().validateAllTenants();

            verify(timeGuardService, never()).validateTenant(anyLong());
        }
    }
}
