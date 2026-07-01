package com.smartlivestock.datagen.interfaces.admin;

import com.smartlivestock.datagen.application.EvaluationService;
import com.smartlivestock.datagen.application.GroundTruthLabelService;
import com.smartlivestock.datagen.application.SynthesisService;
import com.smartlivestock.datagen.application.dto.CreateScenarioRequest;
import com.smartlivestock.datagen.application.dto.EvaluationReport;
import com.smartlivestock.datagen.application.dto.ScenarioDto;
import com.smartlivestock.datagen.domain.model.*;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

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
        scenario.setType(ScenarioType.fromDbValue(req.type()));
        scenario.setStatus(ScenarioStatus.DRAFT);
        scenario.setPenetrationRate(req.penetrationRate() != null ? req.penetrationRate() : 1.0);
        scenario.setWindowStart(Instant.parse(req.windowStart()));
        scenario.setWindowEnd(Instant.parse(req.windowEnd()));
        scenario.setIntervalSeconds(req.intervalSeconds());
        scenario = scenarioRepository.save(scenario);
        return ResponseEntity.ok(ScenarioDto.from(scenario));
    }

    @GetMapping("/scenarios")
    public ResponseEntity<List<ScenarioDto>> listScenarios() {
        return ResponseEntity.ok(scenarioRepository.findAll().stream().map(ScenarioDto::from).toList());
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
            @RequestParam Instant from, @RequestParam Instant to,
            @RequestParam(defaultValue = "0.7") double scoreThreshold) {
        return ResponseEntity.ok(evaluationService.evaluate(from, to, scoreThreshold));
    }
}
