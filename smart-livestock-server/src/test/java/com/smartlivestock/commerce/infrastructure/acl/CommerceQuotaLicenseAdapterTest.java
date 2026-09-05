package com.smartlivestock.commerce.infrastructure.acl;

import com.smartlivestock.licensing.application.DeploymentLicenseQueryService;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the commerce-side license quota adapter (NIX-184 T4c):
 * ONPREM + VALID CURRENT license + payload carries the key, otherwise empty.
 */
@ExtendWith(MockitoExtension.class)
class CommerceQuotaLicenseAdapterTest {

    private static final Long TENANT_ID = 42L;
    private static final String LICENSE_ID = UUID.randomUUID().toString();

    @Mock
    private DeploymentLicenseQueryService queryService;

    private CommerceQuotaLicenseAdapter adapter(String licenseMode) {
        return new CommerceQuotaLicenseAdapter(queryService, licenseMode);
    }

    private DeploymentLicenseQueryService.CurrentLicenseView view(String runtimeStatus,
                                                                  Map<String, Integer> quotas) {
        return new DeploymentLicenseQueryService.CurrentLicenseView(
                UUID.fromString(LICENSE_ID), "ACTIVE", "PREMIUM", runtimeStatus,
                Instant.now().plusSeconds(86400), quotas);
    }

    @Nested
    class HostedMode {

        @Test
        void returnsEmptyRegardlessOfLicense() {
            // Mode short-circuits before the query service is consulted.
            org.mockito.Mockito.lenient()
                    .when(queryService.findCurrentLicense(TENANT_ID))
                    .thenReturn(Optional.empty());

            assertThat(adapter("HOSTED").findLicenseQuota(TENANT_ID, "livestock_management"))
                    .isEmpty();
        }
    }

    @Nested
    class OnPremMode {

        @Test
        void validLicenseWithKey_returnsQuota() {
            when(queryService.findCurrentLicense(TENANT_ID)).thenReturn(Optional.of(
                    view("VALID", Map.of("livestock_management", 500))));

            assertThat(adapter("ONPREM").findLicenseQuota(TENANT_ID, "livestock_management"))
                    .contains(500);
        }

        @Test
        void validLicenseWithoutKey_returnsEmpty() {
            when(queryService.findCurrentLicense(TENANT_ID)).thenReturn(Optional.of(
                    view("VALID", Map.of("livestock_management", 500))));

            assertThat(adapter("ONPREM").findLicenseQuota(TENANT_ID, "device_management"))
                    .isEmpty();
        }

        @Test
        void expiredRuntime_returnsEmpty() {
            when(queryService.findCurrentLicense(TENANT_ID)).thenReturn(Optional.of(
                    view("EXPIRED", Map.of("livestock_management", 500))));

            assertThat(adapter("ONPREM").findLicenseQuota(TENANT_ID, "livestock_management"))
                    .isEmpty();
        }

        @Test
        void suspendedRuntime_returnsEmpty() {
            when(queryService.findCurrentLicense(TENANT_ID)).thenReturn(Optional.of(
                    view("SUSPENDED", Map.of("livestock_management", 500))));

            assertThat(adapter("ONPREM").findLicenseQuota(TENANT_ID, "livestock_management"))
                    .isEmpty();
        }

        @Test
        void noCurrentLicense_returnsEmpty() {
            when(queryService.findCurrentLicense(TENANT_ID)).thenReturn(Optional.empty());

            assertThat(adapter("ONPREM").findLicenseQuota(TENANT_ID, "livestock_management"))
                    .isEmpty();
        }

        @Test
        void modeMatchIsCaseInsensitive() {
            when(queryService.findCurrentLicense(TENANT_ID)).thenReturn(Optional.of(
                    view("VALID", Map.of("livestock_management", 500))));

            assertThat(adapter("onprem").findLicenseQuota(TENANT_ID, "livestock_management"))
                    .contains(500);
        }
    }
}
