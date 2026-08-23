package com.smartlivestock.datagen.interfaces.admin;

import com.smartlivestock.datagen.application.DatagenOperatorContextResolver;
import com.smartlivestock.datagen.application.behavior.BehaviorAnalysisOrchestrationService;
import com.smartlivestock.datagen.application.behavior.BehaviorDatasetPersistenceService;
import com.smartlivestock.datagen.application.behavior.BehaviorEvaluationService;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorAnalyzeRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorDatasetGenerateRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorDatasetStatusDto;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorEvaluationReport;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorEvaluationRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorModelTrainRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformTraining;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/datagen/behavior")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")
public class DataGenBehaviorController {
    private final DatagenOperatorContextResolver operatorContextResolver;
    private final BehaviorDatasetPersistenceService persistenceService;
    private final BehaviorEvaluationService evaluationService;
    private final BehaviorAnalysisOrchestrationService analysisService;

    @PostMapping("/datasets")
    public ResponseEntity<ApiResponse<BehaviorDatasetStatusDto>> generate(
            @RequestBody BehaviorDatasetGenerateRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                persistenceService.generate(request, operatorContextResolver.resolve())));
    }

    @GetMapping("/datasets/{id}")
    public ResponseEntity<ApiResponse<BehaviorDatasetStatusDto>> inspect(
            @PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(
                persistenceService.inspect(id, operatorContextResolver.resolve())));
    }

    @PostMapping("/evaluations")
    public ResponseEntity<ApiResponse<BehaviorEvaluationReport>> evaluate(
            @RequestBody BehaviorEvaluationRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                evaluationService.evaluate(request, operatorContextResolver.resolve())));
    }

    @PostMapping("/datasets/{id}/models/train")
    public ResponseEntity<ApiResponse<BehaviorPlatformTraining>> train(
            @PathVariable UUID id,
            @RequestBody BehaviorModelTrainRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                analysisService.train(id, request, operatorContextResolver.resolve())));
    }

    @PostMapping("/datasets/{id}/analyze")
    public ResponseEntity<ApiResponse<BehaviorAnalysisOrchestrationService.AnalysisResult>> analyze(
            @PathVariable UUID id,
            @RequestBody(required = false) BehaviorAnalyzeRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                analysisService.analyze(id, request, operatorContextResolver.resolve())));
    }
}
