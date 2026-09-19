package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsQualityFlagSummary;
import com.smartlivestock.iot.domain.repository.GpsQualityFlagRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityFlagJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaGpsQualityFlagRepositoryImpl implements GpsQualityFlagRepository {

    private final SpringDataGpsQualityFlagRepository springData;

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void increment(Long deviceId, String ruleName, LocalDate day, String reason) {
        GpsQualityFlagJpaEntity entity = springData
                .findByDeviceIdAndRuleNameAndFlagDay(deviceId, ruleName, day)
                .orElseGet(() -> {
                    GpsQualityFlagJpaEntity e = new GpsQualityFlagJpaEntity();
                    e.setDeviceId(deviceId);
                    e.setRuleName(ruleName);
                    e.setFlagDay(day);
                    return e;
                });
        entity.setFlagCount(entity.getFlagCount() + 1);
        entity.setLastReason(truncate(reason));
        entity.setUpdatedAt(Instant.now());
        springData.save(entity);
    }

    @Override
    public List<GpsQualityFlagSummary> summarize(Instant from, Instant to) {
        return springData.summarizeRowsByRuleAndDay(from, to).stream()
                .map(row -> new GpsQualityFlagSummary(
                        null,
                        (String) row[0],
                        (LocalDate) row[1],
                        ((Number) row[2]).longValue(),
                        ((Number) row[3]).longValue()))
                .toList();
    }

    @Override
    public List<GpsQualityFlagSummary> summarizeByDevice(Instant from, Instant to) {
        return springData.summarizeRowsByDevice(from, to).stream()
                .map(row -> new GpsQualityFlagSummary(
                        ((Number) row[0]).longValue(),
                        (String) row[1],
                        null,
                        ((Number) row[2]).longValue(),
                        1))
                .toList();
    }

    static LocalDate toUtcDay(Instant recordedAt) {
        return recordedAt == null
                ? LocalDate.now(ZoneOffset.UTC)
                : recordedAt.atZone(ZoneOffset.UTC).toLocalDate();
    }

    private String truncate(String reason) {
        if (reason == null) return null;
        return reason.length() <= 255 ? reason : reason.substring(0, 255);
    }
}
