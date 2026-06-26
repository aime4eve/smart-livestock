package com.smartlivestock.datagen.application;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

/**
 * Daily data retention: keeps a rolling N-day window of time-series data.
 * For partitioned health tables, drops entire monthly partitions that are
 * fully outside the retention window (fast, space reclaimed immediately).
 * For unpartitioned tables (gps_logs), uses DELETE (space reclaimed by autovacuum).
 * Also ensures future monthly partitions exist so data always has a landing zone.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DataRetentionService {

    private final EntityManager entityManager;

    @Value("${datagen.retention-days:30}")
    private int retentionDays;

    private static final String[] PARTITIONED_TABLES = {
        "temperature_logs", "rumen_motility_logs", "activity_logs"
    };

    /**
     * Daily purge: drop old partitions + delete old unpartitioned rows.
     */
    @Scheduled(cron = "${datagen.retention-cron:0 0 3 * * *}")
    @Transactional
    public void purgeOldData() {
        LocalDate cutoff = LocalDate.now().minusDays(retentionDays);
        log.info("Data retention purge: cutoff={}, {}-day window", cutoff, retentionDays);

        for (String table : PARTITIONED_TABLES) {
            dropOldPartitions(table, cutoff);
        }
        deleteOldGpsLogs(cutoff);
        deleteOldResolvedAlerts(cutoff);
    }

    /**
     * Monthly: ensure partitions exist for current + next 2 months.
     */
    @Scheduled(cron = "0 0 2 25 * *")
    @Transactional
    public void ensureFuturePartitions() {
        YearMonth base = YearMonth.now();
        for (int i = 0; i <= 2; i++) {
            YearMonth month = base.plusMonths(i);
            for (String table : PARTITIONED_TABLES) {
                ensurePartition(table, month);
            }
        }
        log.info("Partition check: ensured current+2 months for {} tables", PARTITIONED_TABLES.length);
    }

    @SuppressWarnings("unchecked")
    private void dropOldPartitions(String parentTable, LocalDate cutoff) {
        List<String> partitions = entityManager.createNativeQuery(
            "SELECT c.relname FROM pg_inherits i " +
            "JOIN pg_class c ON i.inhrelid = c.oid " +
            "JOIN pg_class p ON i.inhparent = p.oid " +
            "WHERE p.relname = :parent AND c.relname <> :skip")
            .setParameter("parent", parentTable)
            .setParameter("skip", parentTable + "_default")
            .getResultList();

        int dropped = 0;
        for (String name : partitions) {
            String suffix = name.substring(parentTable.length() + 1); // after "parentTable_"
            String[] parts = suffix.split("_");
            if (parts.length != 2) continue;
            try {
                YearMonth ym = YearMonth.of(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]));
                if (ym.atEndOfMonth().isBefore(cutoff)) {
                    entityManager.createNativeQuery("DROP TABLE IF EXISTS " + name).executeUpdate();
                    dropped++;
                    log.info("Dropped partition: {}", name);
                }
            } catch (NumberFormatException ignored) {
            }
        }
        if (dropped > 0) {
            log.info("Purged {} partition(s) from {}", dropped, parentTable);
        }
    }

    private void deleteOldGpsLogs(LocalDate cutoff) {
        int deleted = entityManager.createNativeQuery(
            "DELETE FROM gps_logs WHERE recorded_at < :cutoff")
            .setParameter("cutoff", cutoff.atStartOfDay())
            .executeUpdate();
        if (deleted > 0) {
            log.info("Deleted {} old gps_logs rows (before {})", deleted, cutoff);
        }
    }

    private void deleteOldResolvedAlerts(LocalDate cutoff) {
        int deleted = entityManager.createNativeQuery(
            "DELETE FROM alerts WHERE status IN ('DISMISSED','AUTO_RESOLVED') AND created_at < :cutoff")
            .setParameter("cutoff", cutoff.atStartOfDay())
            .executeUpdate();
        if (deleted > 0) {
            log.info("Deleted {} old resolved alerts (before {})", deleted, cutoff);
        }
    }

    private void ensurePartition(String parentTable, YearMonth month) {
        String partitionName = parentTable + "_" + month.toString().replace("-", "_");
        String start = month.atDay(1).toString();
        String end = month.plusMonths(1).atDay(1).toString();
        entityManager.createNativeQuery(String.format(
            "CREATE TABLE IF NOT EXISTS %s PARTITION OF %s FOR VALUES FROM ('%s') TO ('%s')",
            partitionName, parentTable, start, end)).executeUpdate();
    }
}
