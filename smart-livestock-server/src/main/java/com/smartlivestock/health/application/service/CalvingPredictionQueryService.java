package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.CalvingPredictionItem;
import com.smartlivestock.health.application.dto.HealthDtos.CalvingPredictionListResponse;
import com.smartlivestock.health.domain.model.CalvingPrediction;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.CalvingPredictionRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Read side of the calving prediction list (NIX-389 Task 1): the latest
 * calving_predictions row per livestock of a farm, joined with the livestock
 * code and gated by the same {@code calving_warning} feature gate that feeds
 * the tiles. Kept apart from the evaluation service
 * ({@link CalvingPredictionApplicationService}) so the read path stays free
 * of the scorer's write semantics — same split as estrus list vs. scoring.
 */
@Service
@RequiredArgsConstructor
public class CalvingPredictionQueryService {

    /** Same gate the evaluation writes under and the overview tiles read. */
    static final String FEATURE_KEY = "calving_warning";
    /**
     * List floor: heads whose current snapshot calving_risk_score is >= 50
     * appear in the list (>= 70 alert band, 50-69 watch band — the same
     * accounting as the scene tile counts). Heads without a snapshot or with
     * a null/lower score are not listed.
     */
    static final int LIST_MIN_SNAPSHOT_SCORE = 50;
    /** Default and maximum LIMIT for the list query (abuse guard). */
    static final int DEFAULT_LIMIT = 200;
    static final int MAX_LIMIT = 500;

    private final CalvingPredictionRepository predictionRepo;
    private final HealthSnapshotRepository snapshotRepo;
    private final HealthSubscriptionPort subscriptionPort;
    private final RanchQueryPort ranchQueryPort;

    @Transactional(readOnly = true)
    public CalvingPredictionListResponse getCalvingPredictions(Long farmId, int limit) {
        if (!subscriptionPort.hasFeature(FEATURE_KEY)) {
            // Same rejection shape as the drinking peer comparison guard.
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.calving.premiumRequired");
        }

        List<CalvingPrediction> rows = predictionRepo
                .findLatestPerLivestockByFarm(farmId, clampLimit(limit));

        // Current snapshot score per head: the list membership criterion is
        // the snapshot score (what the tile counts read), not the prediction
        // row's own score, so a just-superseded row cannot keep a released
        // head in the list. Livestock without a snapshot are not listed.
        Map<Long, Integer> snapshotScores = new LinkedHashMap<>();
        for (HealthSnapshot snapshot : snapshotRepo.findByFarmId(farmId)) {
            if (snapshot.getCalvingRiskScore() != null) {
                snapshotScores.putIfAbsent(snapshot.getLivestockId(), snapshot.getCalvingRiskScore());
            }
        }

        List<CalvingPredictionItem> items = rows.stream()
                .filter(row -> snapshotScores.getOrDefault(row.getLivestockId(), 0) >= LIST_MIN_SNAPSHOT_SCORE)
                // Highest risk first, mirroring the estrus list ordering.
                .sorted(Comparator.comparingInt(CalvingPrediction::getRiskScore).reversed())
                .map(row -> {
                    String code = ranchQueryPort.findLivestockById(row.getLivestockId())
                            .map(LivestockInfo::livestockCode).orElse("?");
                    return new CalvingPredictionItem(
                            String.valueOf(row.getLivestockId()),
                            code,
                            row.getRiskScore(),
                            row.getPredictedAt(),
                            row.getExpectedWindowStart(),
                            row.getExpectedWindowEnd(),
                            row.getTempDropCelsius(),
                            row.getActivityRatio(),
                            row.getPriorEnabled());
                })
                .toList();

        return new CalvingPredictionListResponse(items);
    }

    /** Clamp the client-supplied limit into [1, {@link #MAX_LIMIT}]. */
    static int clampLimit(int limit) {
        return Math.max(1, Math.min(limit, MAX_LIMIT));
    }
}
