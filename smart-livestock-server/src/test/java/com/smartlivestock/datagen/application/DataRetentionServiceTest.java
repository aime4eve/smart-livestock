package com.smartlivestock.datagen.application;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DataRetentionServiceTest {
    @Mock
    private EntityManager entityManager;

    private DataRetentionService service;

    @BeforeEach
    void setUp() {
        service = new DataRetentionService(entityManager);
        ReflectionTestUtils.setField(service, "retentionDays", 30);
    }

    @Test
    void purgeOldData_dropsAllTimeSeriesPartitionsAndDeletesLegacyRows() {
        when(entityManager.createNativeQuery(anyString())).thenAnswer(invocation -> {
            Query query = mock(Query.class);
            when(query.setParameter(anyString(), any())).thenReturn(query);
            when(query.executeUpdate()).thenReturn(0);
            return query;
        });

        service.purgeOldData();

        verify(entityManager, times(4)).createNativeQuery(contains("pg_inherits"));
        verify(entityManager).createNativeQuery(contains("DELETE FROM gps_logs"));
        verify(entityManager).createNativeQuery(contains("DELETE FROM alert_read_status"));
        verify(entityManager).createNativeQuery(contains("DELETE FROM alerts"));
    }
}
