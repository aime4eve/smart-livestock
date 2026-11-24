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
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.SimpleTransactionStatus;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Partition maintenance must never take the application down: a contended
 * table (telemetry consumers hold reads while CREATE PARTITION wants an
 * exclusive lock — observed as a startup deadlock 2026-11-24) fails fast per
 * table and the remaining tables are still maintained.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PartitionMaintenanceServiceTest {
    @Mock
    private EntityManager entityManager;

    private PartitionMaintenanceService service;

    @BeforeEach
    void setUp() {
        TransactionTemplate template = new TransactionTemplate(noOpTransactionManager());
        service = new PartitionMaintenanceService(entityManager, template);
        ReflectionTestUtils.setField(service, "monthsAhead", 2);
        ReflectionTestUtils.setField(service, "lockTimeout", Duration.ofSeconds(5));
    }

    private PlatformTransactionManager noOpTransactionManager() {
        return new PlatformTransactionManager() {
            @Override
            public TransactionStatus getTransaction(TransactionDefinition definition) {
                return new SimpleTransactionStatus();
            }

            @Override
            public void commit(TransactionStatus status) {
            }

            @Override
            public void rollback(TransactionStatus status) {
            }
        };
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

        // 5 tables, each in its own transaction (5 lock-timeout settings).
        verify(entityManager, times(5)).createNativeQuery(contains("set_config"));
        verify(entityManager, times(5)).createNativeQuery(contains("rebalance_default_partition"));
        verify(entityManager, times(15)).createNativeQuery(contains("ensure_month_partition"));
        verify(entityManager, times(5)).createNativeQuery(contains("COUNT(*)"));
        assertEquals(1, sqls.stream().filter(sql -> sql.contains("temperature_logs_default")).count());
        assertEquals(1, sqls.stream().filter(sql -> sql.contains("device_telemetry_logs_default")).count());
        assertEquals(1, sqls.stream().filter(sql -> sql.contains("anomaly_scores_default")).count());
    }

    @Test
    void contendedTableIsSkippedAndRemainingTablesAreStillMaintained() {
        when(entityManager.createNativeQuery(anyString())).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0);
            Query query = mock(Query.class);
            when(query.setParameter(anyString(), any())).thenReturn(query);
            if (sql.contains("rebalance_default_partition")) {
                // Contended table: the rebalance dies mid-transaction.
                when(query.getSingleResult()).thenAnswer(a ->
                        "public.activity_logs".equals(String.valueOf(query.getParameterValue("table")))
                                ? raiseDeadlock() : 0);
            } else {
                when(query.getSingleResult()).thenReturn(0L);
            }
            return query;
        });

        assertDoesNotThrow(service::ensureCurrentAndFuturePartitions);

        // Every table was still attempted (5 rebalances, 5 transactions) even
        // though activity_logs failed.
        verify(entityManager, times(5)).createNativeQuery(contains("set_config"));
        verify(entityManager, times(5)).createNativeQuery(contains("rebalance_default_partition"));
    }

    private static Number raiseDeadlock() {
        throw new IllegalStateException("deadlock detected");
    }
}
