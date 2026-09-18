package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GatewayDistanceProfileRow;
import com.smartlivestock.iot.domain.repository.GatewayDistanceProfileRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GatewayDistanceProfileJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaGatewayDistanceProfileRepositoryImpl implements GatewayDistanceProfileRepository {

    private final SpringDataGatewayDistanceProfileRepository springData;

    @Override
    @Transactional
    public void replaceAll(String gatewayId, List<GatewayDistanceProfileRow> rows, int windowDays) {
        springData.deleteByGatewayId(gatewayId);
        Instant now = Instant.now();
        for (GatewayDistanceProfileRow row : rows) {
            GatewayDistanceProfileJpaEntity e = new GatewayDistanceProfileJpaEntity();
            e.setGatewayId(gatewayId);
            e.setBucketRssi(row.bucketRssi());
            e.setSampleCount(row.sampleCount());
            e.setDistP50M(BigDecimal.valueOf(row.p50Meters()));
            e.setDistP90M(BigDecimal.valueOf(row.p90Meters()));
            e.setWindowDays(windowDays);
            e.setComputedAt(now);
            springData.save(e);
        }
    }

    @Override
    public List<GatewayDistanceProfileRow> findByGatewayId(String gatewayId) {
        return springData.findByGatewayIdOrderByBucketRssi(gatewayId).stream()
                .map(e -> new GatewayDistanceProfileRow(
                        e.getBucketRssi(),
                        e.getSampleCount(),
                        e.getDistP50M().doubleValue(),
                        e.getDistP90M().doubleValue()))
                .toList();
    }

    @Override
    public List<String> findGatewaysWithProfile() {
        return springData.findAll().stream()
                .map(GatewayDistanceProfileJpaEntity::getGatewayId)
                .distinct()
                .toList();
    }
}
