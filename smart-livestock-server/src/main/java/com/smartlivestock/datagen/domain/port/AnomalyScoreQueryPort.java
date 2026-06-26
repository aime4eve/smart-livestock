package com.smartlivestock.datagen.domain.port;

import com.smartlivestock.datagen.domain.port.dto.AnomalyScoreInfo;

import java.time.Instant;
import java.util.List;

/** ACL port: datagen -> Health. Reads anomaly_scores for evaluation. */
public interface AnomalyScoreQueryPort {
    List<AnomalyScoreInfo> findByLivestockIdsAndPeriod(List<Long> livestockIds, Instant from, Instant to);
}
