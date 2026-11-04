package com.smartlivestock.health.interfaces.admin;

import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.BaselineEvaluationReport;
import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.BaselineEvaluationRequest;
import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.BaselineRecalculateHead;
import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.BaselineRecalculateRequest;
import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.BaselineRecalculateResponse;
import com.smartlivestock.health.application.service.BaselineEvaluationService;
import com.smartlivestock.health.application.service.IndividualBaselineLearningService;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.service.BaselineLearningResult;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

/**
 * Admin endpoints of the individual temperature baseline learning
 * (plan 2026-11-03 Task 5). Two endpoints with opposite natures:
 *
 * <ul>
 *   <li><b>recalculate</b> — write path: learns and UPDATES the snapshot
 *       baseline (manual/dev/ops compensation, throttle bypassed);</li>
 *   <li><b>evaluations</b> — strictly read-only A/B comparison of the same
 *       event sequence under the DEFAULT vs the LEARNED candidate baseline;
 *       it never writes scores, snapshots or alerts.</li>
 * </ul>
 *
 * <p>Class-level @PreAuthorize mirrors {@link DrinkingRecalcAdminController}.
 * The farm sweep runs here (not inside the learning service) so every head
 * goes through the proxied {@code recalculate} — a same-bean self-invocation
 * would silently bypass its REQUIRES_NEW transaction (see
 * DrinkingRecalculationService for the same ruling).</p>
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/admin/health/baseline-learning")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")
public class BaselineLearningAdminController {

    private final IndividualBaselineLearningService learningService;
    private final BaselineEvaluationService evaluationService;
    private final HealthSnapshotRepository snapshotRepo;

    /**
     * Write path: recalculate the learned baseline. Body
     * {@code {livestockId?: Long, farmId?: Long}} — one of the two is
     * required (both missing → VALIDATION_ERROR); livestockId wins when
     * both are present. With farmId, every livestock of the farm that owns
     * a health snapshot is recalculated head by head; a failing head is
     * logged (warn) and the sweep continues.
     */
    @PostMapping("/recalculate")
    public ResponseEntity<ApiResponse<BaselineRecalculateResponse>> recalculate(
            @RequestBody BaselineRecalculateRequest request) {
        Long livestockId = request == null ? null : request.livestockId();
        Long farmId = request == null ? null : request.farmId();
        if (livestockId == null && farmId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "error.health.baselineRecalcTargetRequired");
        }

        List<Long> targets = livestockId != null
                ? List.of(livestockId)
                : snapshotRepo.findByFarmId(farmId).stream()
                        .map(HealthSnapshot::getLivestockId)
                        .toList();

        List<BaselineRecalculateHead> results = new ArrayList<>(targets.size());
        int learnedNow = 0;
        for (Long target : targets) {
            try {
                BaselineLearningResult result = learningService.recalculate(target, true);
                if (result == null) {
                    // No snapshot for this head (throttle is bypassed for
                    // manual runs) — nothing was learned.
                    results.add(new BaselineRecalculateHead(target, false, null, null, true));
                } else {
                    if (result.learnedNow()) {
                        learnedNow++;
                    }
                    results.add(new BaselineRecalculateHead(target, result.learnedNow(),
                            result.baselineTemp(), result.qualifiedDays(), result.insufficientData()));
                }
            } catch (Exception e) {
                // One bad head must not stop the farm sweep — each head runs
                // in its own REQUIRES_NEW transaction inside the service.
                log.warn("Manual baseline recalculation failed for livestock {}: {}",
                        target, e.getMessage());
                results.add(new BaselineRecalculateHead(target, false, null, null, true));
            }
        }
        return ResponseEntity.ok(ApiResponse.ok(
                new BaselineRecalculateResponse(targets.size(), learnedNow, results)));
    }

    /**
     * Read-only: A/B evaluation of one livestock (same event sequence under
     * the DEFAULT vs the LEARNED candidate baseline). Never writes — see
     * {@link BaselineEvaluationService} for the mechanism-comparison boundary.
     */
    @PostMapping("/evaluations")
    public ResponseEntity<ApiResponse<BaselineEvaluationReport>> evaluate(
            @RequestBody BaselineEvaluationRequest request) {
        Long livestockId = request == null ? null : request.livestockId();
        Integer windowDays = request == null ? null : request.windowDays();
        return ResponseEntity.ok(ApiResponse.ok(evaluationService.evaluate(livestockId, windowDays)));
    }
}
