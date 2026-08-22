package com.smartlivestock.platform.application;

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

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PartitionMaintenanceServiceTest {
    @Mock
    private EntityManager entityManager;

    private PartitionMaintenanceService service;

    @BeforeEach
    void setUp() {
        service = new PartitionMaintenanceService(entityManager);
        ReflectionTestUtils.setField(service, "monthsAhead", 2);
    }

    @Test
    void ensureCurrentAndFuturePartitions_coversAllTablesAndMonitorsDefault() {
        List<String> sqls = new ArrayList<>();
        when(entityManager.createNativeQuery(anyString())).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0);
            sqls.add(sql);
            Query query = mock(Query.class);
            when(query.setParameter(anyString(), any())).thenReturn(query);
            when(query.getSingleResult()).thenReturn(sql.contains("COUNT(*)") ? 0L : 0L);
            return query;
        });

        service.ensureCurrentAndFuturePartitions();

        verify(entityManager, times(5)).createNativeQuery(contains("rebalance_default_partition"));
        verify(entityManager, times(15)).createNativeQuery(contains("ensure_month_partition"));
        verify(entityManager, times(5)).createNativeQuery(contains("COUNT(*)"));
        assertEquals(1, sqls.stream().filter(sql -> sql.contains("temperature_logs_default")).count());
        assertEquals(1, sqls.stream().filter(sql -> sql.contains("device_telemetry_logs_default")).count());
        assertEquals(1, sqls.stream().filter(sql -> sql.contains("anomaly_scores_default")).count());
    }
}
