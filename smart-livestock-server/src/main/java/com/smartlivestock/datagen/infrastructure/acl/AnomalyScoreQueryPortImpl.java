package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.port.AnomalyScoreQueryPort;
import com.smartlivestock.datagen.domain.port.dto.AnomalyScoreInfo;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class AnomalyScoreQueryPortImpl implements AnomalyScoreQueryPort {
    private final EntityManager entityManager;
    private volatile boolean available = true;

    @Override
    @SuppressWarnings("unchecked")
    public List<AnomalyScoreInfo> findByLivestockIdsAndPeriod(List<Long> livestockIds, Instant from, Instant to) {
        if (!available || livestockIds.isEmpty()) return List.of();
        try {
            var query = entityManager.createNativeQuery(
                "SELECT livestock_id, anomaly_score, anomaly_type, created_at " +
                "FROM anomaly_scores " +
                "WHERE livestock_id IN (:ids) AND created_at >= :from AND created_at <= :to");
            query.setParameter("ids", livestockIds);
            query.setParameter("from", from);
            query.setParameter("to", to);
            List<Object[]> rows = query.getResultList();
            return rows.stream().map(row -> new AnomalyScoreInfo(
                ((Number) row[0]).longValue(),
                row[1] instanceof BigDecimal bd ? bd : new BigDecimal(row[1].toString()),
                (String) row[2],
                row[3] instanceof Instant i ? i : ((Timestamp) row[3]).toInstant()
            )).toList();
        } catch (PersistenceException e) {
            available = false;
            log.warn("anomaly_scores table not available, evaluation will be empty: {}", e.getMessage());
            return List.of();
        }
    }
}
