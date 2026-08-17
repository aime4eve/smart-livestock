package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.repository.DatagenDeviceAssignmentRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DatagenDataQueryServiceTest {
    @Mock private DatagenDeviceAssignmentRepository assignmentRepository;
    @Mock private EntityManager entityManager;
    private DatagenDataQueryService service;

    @Test
    void clear_executesDeleteStatements() throws Exception {
        service = new DatagenDataQueryService(assignmentRepository);
        var entityManagerField = DatagenDataQueryService.class.getDeclaredField("entityManager");
        entityManagerField.setAccessible(true);
        entityManagerField.set(service, entityManager);

        Query deviceIdsQuery = mock(Query.class);
        Query countQuery = mock(Query.class);
        Query deleteQuery = mock(Query.class);
        when(deviceIdsQuery.setParameter(anyString(), any()))
                .thenAnswer(invocation -> invocation.getMock());
        when(countQuery.setParameter(anyString(), any()))
                .thenAnswer(invocation -> invocation.getMock());
        when(deleteQuery.setParameter(anyString(), any()))
                .thenAnswer(invocation -> invocation.getMock());
        when(entityManager.createNativeQuery(anyString()))
                .thenAnswer(invocation -> {
                    String sql = invocation.getArgument(0, String.class);
                    if (sql.startsWith("SELECT DISTINCT")) return deviceIdsQuery;
                    return sql.startsWith("DELETE FROM") ? deleteQuery : countQuery;
                });
        when(entityManager.createNativeQuery(anyString(), eq(Long.class)))
                .thenAnswer(invocation -> invocation.getArgument(0, String.class)
                        .startsWith("SELECT DISTINCT") ? deviceIdsQuery : countQuery);
        when(deviceIdsQuery.getResultStream()).thenReturn(List.of(5L).stream());
        when(countQuery.getSingleResult()).thenReturn(0L);
        when(deleteQuery.executeUpdate()).thenReturn(1);

        var result = service.clear(
                1L, Instant.parse("2026-08-17T00:00:00Z"),
                Instant.parse("2026-08-17T23:59:59Z"));

        assertEquals(1, result.telemetryRows());
        verify(deleteQuery, atLeastOnce()).executeUpdate();
    }
}
