package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.port.AlertQueryPort;
import com.smartlivestock.datagen.domain.port.dto.AlertInfo;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;

/**
 * ACL: datagen -> Ranch alerts table.
 * Uses native query to read fence alerts directly, since Alert domain model
 * doesn't expose createdAt (it's in the JPA entity only).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AlertQueryPortImpl implements AlertQueryPort {
    private final EntityManager entityManager;

    @Override
    @SuppressWarnings("unchecked")
    public List<AlertInfo> findFenceAlertsByLivestockIds(List<Long> livestockIds, Instant from, Instant to) {
        if (livestockIds.isEmpty()) return List.of();
        try {
            var query = entityManager.createNativeQuery(
                "SELECT id, livestock_id, type, status, created_at " +
                "FROM alerts " +
                "WHERE livestock_id IN (:ids) " +
                "AND type IN ('FENCE_BREACH', 'FENCE_APPROACH') " +
                "AND created_at >= :from AND created_at <= :to");
            query.setParameter("ids", livestockIds);
            query.setParameter("from", from);
            query.setParameter("to", to);
            List<Object[]> rows = query.getResultList();
            return rows.stream().map(row -> {
                Instant created = row[4] instanceof Instant i
                        ? i : ((java.sql.Timestamp) row[4]).toInstant();
                return new AlertInfo(
                        ((Number) row[0]).longValue(),
                        ((Number) row[1]).longValue(),
                        (String) row[2],
                        (String) row[3],
                        created);
            }).toList();
        } catch (PersistenceException e) {
            log.warn("alerts table query failed: {}", e.getMessage());
            return List.of();
        }
    }
}
