package com.smartlivestock.platform.application;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.YearMonth;

/**
 * Keeps monthly time-series partitions ready and reports rows left in default.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PartitionMaintenanceService {

    static final String[] PARTITIONED_TABLES = {
        "temperature_logs",
        "rumen_motility_logs",
        "activity_logs",
        "device_telemetry_logs",
        "anomaly_scores"
    };

    private final EntityManager entityManager;

    @Value("${platform.partition.months-ahead:2}")
    private int monthsAhead;

    @EventListener(ApplicationReadyEvent.class)
    @Scheduled(cron = "${platform.partition.check-cron:0 10 2 * * *}")
    @Transactional
    public void ensureCurrentAndFuturePartitions() {
        for (String table : PARTITIONED_TABLES) {
            rebalanceDefaultPartition(table);
            for (int i = 0; i <= monthsAhead; i++) {
                ensureMonthPartition(table, YearMonth.now().plusMonths(i));
            }
            logDefaultPartitionCount(table);
        }
        log.info("Partition maintenance completed for current + {} months", monthsAhead);
    }

    private void rebalanceDefaultPartition(String table) {
        Number moved = (Number) entityManager.createNativeQuery(
                "SELECT partition_ops.rebalance_default_partition(to_regclass(:table))")
            .setParameter("table", "public." + table)
            .getSingleResult();
        if (moved.longValue() > 0) {
            log.warn("Moved {} row(s) from {} default partition to monthly partitions",
                    moved.longValue(), table);
        }
    }

    private void ensureMonthPartition(String table, YearMonth month) {
        Number moved = (Number) entityManager.createNativeQuery(
                "SELECT partition_ops.ensure_month_partition(to_regclass(:table), :month)")
            .setParameter("table", "public." + table)
            .setParameter("month", month.atDay(1))
            .getSingleResult();
        if (moved.longValue() > 0) {
            log.warn("Created {} partition for {} and moved {} row(s) from default",
                    month, table, moved.longValue());
        }
    }

    private void logDefaultPartitionCount(String table) {
        Number count = (Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM public." + table + "_default")
            .getSingleResult();
        if (count.longValue() > 0) {
            log.warn("Table {} default partition still contains {} row(s)", table, count.longValue());
        }
    }
}
