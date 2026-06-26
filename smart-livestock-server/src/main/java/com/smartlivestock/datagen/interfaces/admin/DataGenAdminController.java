package com.smartlivestock.datagen.interfaces.admin;

import com.smartlivestock.datagen.application.EvaluationService;
import com.smartlivestock.datagen.application.GroundTruthLabelService;
import com.smartlivestock.datagen.application.SynthesisService;
import com.smartlivestock.datagen.application.dto.CreateScenarioRequest;
import com.smartlivestock.datagen.application.dto.EvaluationReport;
import com.smartlivestock.datagen.application.dto.ScenarioDto;
import com.smartlivestock.datagen.domain.model.AnomalyPattern;
import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

/**
 * Admin API for datagen context.
 * Only platform_admin / b2b_admin can access (covered by SecurityConfig rules for /api/v1/admin/**).
 *
 * All responses use DTOs, not domain entities (review P2 #11).
 */
@RestController
@RequestMapping("/api/v1/admin/datagen")
@RequiredArgsConstructor
public class DataGenAdminController {

    private final SynthesisService synthesisService;
    private final SynthesisScenarioRepository scenarioRepository;
    private final GroundTruthLabelService labelService;
    private final EvaluationService evaluationService;

    @PostMapping("/scenarios")
    public ResponseEntity<ScenarioDto> createScenario(@RequestBody CreateScenarioRequest req) {
        SynthesisScenario scenario = new SynthesisScenario();
        scenario.setName(req.name());
        scenario.setScenarioType(req.scenarioType() != null
                ? com.smartlivestock.datagen.domain.model.ScenarioType.valueOf(req.scenarioType())
                : com.smartlivestock.datagen.domain.model.ScenarioType.HEALTH);
        scenario.setPattern(req.pattern() != null
                ? AnomalyPattern.fromDbValue(req.pattern())
                : AnomalyPattern.NORMAL);
        scenario.setStatus(ScenarioStatus.DRAFT);
        scenario.setPenetrationRate(req.penetrationRate() != null ? req.penetrationRate() : 1.0);
        scenario.setWindowStart(Instant.parse(req.windowStart()));
        scenario.setWindowEnd(Instant.parse(req.windowEnd()));
        scenario.setIntervalSeconds(req.intervalSeconds() != null ? req.intervalSeconds() : 30);
        scenario = scenarioRepository.save(scenario);
        return ResponseEntity.ok(ScenarioDto.from(scenario));
    }

    @GetMapping("/scenarios")
    public ResponseEntity<List<ScenarioDto>> listScenarios() {
        return ResponseEntity.ok(scenarioRepository.findAll().stream()
                .map(ScenarioDto::from).toList());
    }

    @PostMapping("/scenarios/{id}/start")
    public ResponseEntity<Void> startScenario(@PathVariable Long id) {
        SynthesisScenario s = scenarioRepository.findById(id).orElseThrow();
        s.start();
        scenarioRepository.save(s);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/scenarios/{id}/stop")
    public ResponseEntity<Void> stopScenario(@PathVariable Long id) {
        SynthesisScenario s = scenarioRepository.findById(id).orElseThrow();
        s.stop();
        scenarioRepository.save(s);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/labels")
    public ResponseEntity<List<GroundTruthLabel>> listLabels(
            @RequestParam(required = false) Long livestockId,
            @RequestParam(required = false) Instant from,
            @RequestParam(required = false) Instant to) {
        if (livestockId != null && from != null && to != null) {
            return ResponseEntity.ok(labelService.findByLivestockAndPeriod(livestockId, from, to));
        }
        return ResponseEntity.ok(List.of());
    }

    @GetMapping("/evaluation")
    public ResponseEntity<EvaluationReport> evaluate(
            @RequestParam Instant from,
            @RequestParam Instant to,
            @RequestParam(defaultValue = "0.7") double scoreThreshold) {
        return ResponseEntity.ok(evaluationService.evaluate(from, to, scoreThreshold));
    }
}
