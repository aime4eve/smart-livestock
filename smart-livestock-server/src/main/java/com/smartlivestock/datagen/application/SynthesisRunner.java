package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "datagen.enabled", havingValue = "true", matchIfMissing = true)
public class SynthesisRunner {

    private final SynthesisService synthesisService;
    private final SynthesisScenarioRepository scenarioRepository;
    private final ConcurrentHashMap<Long, Instant> lastRunTimes = new ConcurrentHashMap<>();

    @Scheduled(fixedRateString = "${datagen.tick-ms:10000}")
    public void run() {
        List<SynthesisScenario> active = scenarioRepository.findByStatus(ScenarioStatus.RUNNING);
        if (active.isEmpty()) {
            log.debug("No RUNNING scenarios - skipping");
            return;
        }
        Instant now = Instant.now();
        for (SynthesisScenario scenario : active) {
            int interval = scenario.effectiveIntervalSeconds();
            Instant lastRun = lastRunTimes.get(scenario.getId());
            if (lastRun == null || Duration.between(lastRun, now).getSeconds() >= interval) {
                try {
                    synthesisService.generate(scenario);
                    lastRunTimes.put(scenario.getId(), now);
                } catch (Exception e) {
                    log.error("Synthesis failed for [{}]: {}", scenario.getName(), e.getMessage(), e);
                }
            }
        }
    }
}
