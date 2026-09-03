package com.smartlivestock.licensing.infrastructure;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the tenant-granularity usage counts backing the license
 * quota pre-check (NIX-184 T4).
 */
@ExtendWith(MockitoExtension.class)
class LicenseUsageQueryAdapterTest {

    private static final Long TENANT_ID = 42L;

    @Mock
    private EntityManager entityManager;

    private LicenseUsageQueryAdapter adapter;

    @BeforeEach
    void setUp() {
        adapter = new LicenseUsageQueryAdapter(entityManager);
    }

    private void stubCount(long count) {
        Query query = mock(Query.class);
        when(query.setParameter("tenantId", TENANT_ID)).thenReturn(query);
        when(query.getSingleResult()).thenReturn(count);
        when(entityManager.createNativeQuery(anyString())).thenReturn(query);
    }

    @Nested
    class KnownFeatureKeys {

        @Test
        void livestockUsage_countedFromLivestockJoin() {
            stubCount(123L);

            assertThat(adapter.countCurrentUsage(TENANT_ID, "livestock_management"))
                    .isEqualTo(123);
        }

        @Test
        void deviceUsage_countedFromDevices() {
            stubCount(9L);

            assertThat(adapter.countCurrentUsage(TENANT_ID, "device_management")).isEqualTo(9);
        }

        @Test
        void workerUsage_countedFromAssignments() {
            stubCount(4L);

            assertThat(adapter.countCurrentUsage(TENANT_ID, "worker_management")).isEqualTo(4);
        }

        @Test
        void fenceUsage_countedFromFenceJoin() {
            stubCount(12L);

            assertThat(adapter.countCurrentUsage(TENANT_ID, "fence_management")).isEqualTo(12);
        }
    }

    @Nested
    class UnknownFeatureKeys {

        @Test
        void unknownKey_countsAsZeroWithoutQuerying() {
            assertThat(adapter.countCurrentUsage(TENANT_ID, "unknown_feature")).isZero();

            verify(entityManager, never()).createNativeQuery(anyString());
        }
    }
}
