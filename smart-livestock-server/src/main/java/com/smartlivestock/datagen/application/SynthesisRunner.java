package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Drives the synthetic-data tick on a DEDICATED executor instead of the
 * Spring shared scheduler. Background (2026-09-30): every app container ran
 * exactly ONE full synthesis round and then the shared single-thread
 * scheduler stopped dispatching anything at all — no error, no log, other
 * pools (HTTP, MQ consumers) perfectly alive. A fixedRate task can vanish
 * this way when a Throwable escapes it on some code paths, and a poisoned
 * shared pool starves every @Scheduled task together. A self-managed
 * executor with a catch-Throwable tick survives both failure modes, so the
 * synthetic stream no longer depends on the shared scheduler's health.
 */
@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "datagen.enabled", havingValue = "true", matchIfMissing = true)
public class SynthesisRunner {

    private final SynthesisService synthesisService;
    private final SynthesisScenarioRepository scenarioRepository;

    @Value("${datagen.tick-ms:10000}")
    private long tickMs;

    private ScheduledExecutorService tickExecutor;

    @PostConstruct
    public void start() {
        tickExecutor = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "datagen-synthesis-tick");
            t.setDaemon(true);
            return t;
        });
        // fixedDelay (not fixedRate): a slow round can never queue up.
        tickExecutor.scheduleWithFixedDelay(this::tick, tickMs, tickMs, TimeUnit.MILLISECONDS);
        log.info("Synthesis tick started on a dedicated executor (fixedDelay={}ms)", tickMs);
    }

    void tick() {
        // catch Throwable — a scheduleWithFixedDelay task is cancelled the
        // first time its runnable throws, so nothing below may escape.
        try {
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
        } catch (Throwable t) {
            log.error("Synthesis tick failed - dedicated schedule kept alive", t);
        }
    }

    @PreDestroy
    public void stop() {
        if (tickExecutor != null) {
            tickExecutor.shutdownNow();
        }
    }
}
