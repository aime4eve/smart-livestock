package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "datagen.enabled", havingValue = "true", matchIfMissing = true)
public class SynthesisRunner {

    private final SynthesisService synthesisService;
    private final SynthesisScenarioRepository scenarioRepository;

    @Scheduled(fixedRateString = "${datagen.tick-ms:10000}")
    public void run() {
        List<SynthesisScenario> active = scenarioRepository.findByStatus(ScenarioStatus.RUNNING);
        if (active.isEmpty()) {
            log.debug("No RUNNING scenarios - skipping");
            return;
        }
        for (SynthesisScenario scenario : active) {
            try {
                // SynthesisService applies device-type intervals (tracker/capsule)
                // on every scheduler tick.
                synthesisService.generate(scenario);
            } catch (Exception e) {
                log.error("Synthesis failed for [{}]: {}", scenario.getName(), e.getMessage(), e);
            }
        }
    }
}
