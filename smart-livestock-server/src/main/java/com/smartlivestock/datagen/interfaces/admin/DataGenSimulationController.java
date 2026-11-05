package com.smartlivestock.datagen.interfaces.admin;

import com.smartlivestock.datagen.application.DatagenFarmAccessService;
import com.smartlivestock.datagen.application.DatagenOperatorContext;
import com.smartlivestock.datagen.application.DatagenOperatorContextResolver;
import com.smartlivestock.datagen.application.SimulationEvaluationService;
import com.smartlivestock.datagen.application.SimulationHerdGenerationService;
import com.smartlivestock.datagen.application.dto.SimulationDtos.SimulationEvaluationReport;
import com.smartlivestock.datagen.application.dto.SimulationDtos.SimulationEvaluationRequest;
import com.smartlivestock.datagen.application.dto.SimulationDtos.SimulationHerdGenerateRequest;
import com.smartlivestock.datagen.application.dto.SimulationDtos.SimulationHerdRunResult;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.SimulationHerdParams;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

/**
 * Admin endpoints for the literature-parameterized herd simulation
 * (plan 2026-11-05, Task 2). PLATFORM_ADMIN only — generation writes farm
 * telemetry + ground truth at scale, mirroring the DataGenAdminController
 * permission caliber.
 */
@RestController
@RequestMapping("/api/v1/admin/datagen/simulation")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN')")
public class DataGenSimulationController {

    private static final int DEFAULT_DAYS = 14;
    private static final int DEFAULT_GRANULARITY_MINUTES = 30;

    private final SimulationHerdGenerationService generationService;
    private final SimulationEvaluationService evaluationService;
    private final DatagenOperatorContextResolver operatorContextResolver;
    private final DatagenFarmAccessService farmAccessService;

    @PostMapping("/herd")
    public ResponseEntity<ApiResponse<SimulationHerdRunResult>> generateHerd(
            @RequestBody SimulationHerdGenerateRequest request) {
        DatagenOperatorContext operator = operatorContextResolver.resolve();
        // farmId is required and must exist / be accessible to the operator.
        if (request.farmId() == null) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "error.datagen.farmNotFound",
                    new Object[]{null});
        }
        farmAccessService.requireAccessibleFarm(request.farmId(), operator);

        SimulationHerdParams params = toParams(request);
        SimulationHerdRunResult result = generationService.generate(params, operator.userId());
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    /**
     * POST /evaluation — evaluate one simulation run: regenerate each head's
     * learned baseline, compare it against the generator-known truth and
     * replay the estrus mechanism against the ESTRUS label windows (Task 3).
     * The report's note states the simulated-data boundary by contract.
     */
    @PostMapping("/evaluation")
    public ResponseEntity<ApiResponse<SimulationEvaluationReport>> evaluate(
            @RequestBody SimulationEvaluationRequest request) {
        if (request == null || request.runId() == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.datagen.simulationRunRequired");
        }
        SimulationEvaluationReport report = evaluationService.evaluate(request.runId());
        return ResponseEntity.ok(ApiResponse.ok(report));
    }

    private SimulationHerdParams toParams(SimulationHerdGenerateRequest request) {
        List<Long> livestockIds = request.livestockIds();
        List<Long> deviceIds = request.deviceIds();
        if (livestockIds == null || deviceIds == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.datagen.simulationIdLists");
        }
        // farmZoneId is optional: null/blank → the composer's Asia/Shanghai
        // default; a present-but-invalid id is rejected up front (a compose-time
        // DateTimeException would otherwise surface as a 500).
        String farmZoneId = request.farmZoneId();
        if (farmZoneId != null && !farmZoneId.isBlank()) {
            try {
                java.time.ZoneId.of(farmZoneId);
            } catch (Exception e) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.datagen.invalidRules");
            }
        } else {
            farmZoneId = null; // normalize → the params record applies its default
        }
        int days = request.days() != null ? request.days() : DEFAULT_DAYS;
        int granularity = request.granularityMinutes() != null
                ? request.granularityMinutes() : DEFAULT_GRANULARITY_MINUTES;
        // Seed default derives from the request instant so the run stays
        // replayable from the persisted params JSONB.
        Instant asOf = Instant.now();
        long seed = request.seed() != null ? request.seed() : asOf.toEpochMilli();
        return SimulationHerdParams.defaults(livestockIds, deviceIds, days, granularity, seed, farmZoneId);
    }
}
