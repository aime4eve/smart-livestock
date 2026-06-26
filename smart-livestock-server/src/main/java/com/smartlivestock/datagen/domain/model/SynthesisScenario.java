package com.smartlivestock.datagen.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;
import java.util.List;

public class SynthesisScenario extends AggregateRoot {
    private String name;
    private ScenarioStatus status;
    private ScenarioType scenarioType;
    private AnomalyPattern pattern;
    private double penetrationRate;
    private Instant windowStart;
    private Instant windowEnd;
    private int intervalSeconds;
    private List<Long> targetLivestockIds;

    public SynthesisScenario() {
        this.status = ScenarioStatus.DRAFT;
        this.scenarioType = ScenarioType.HEALTH;
        this.pattern = AnomalyPattern.NORMAL;
    }

    public void start() {
        if (status != ScenarioStatus.DRAFT && status != ScenarioStatus.STOPPED) {
            throw new IllegalStateException("Cannot start scenario in status: " + status);
        }
        this.status = ScenarioStatus.RUNNING;
    }

    public void stop() {
        this.status = ScenarioStatus.STOPPED;
    }

    public boolean isActiveAt(Instant when) {
        return status == ScenarioStatus.RUNNING
                && !when.isBefore(windowStart)
                && when.isBefore(windowEnd);
    }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public ScenarioStatus getStatus() { return status; }
    public void setStatus(ScenarioStatus status) { this.status = status; }
    public ScenarioType getScenarioType() { return scenarioType; }
    public void setScenarioType(ScenarioType scenarioType) { this.scenarioType = scenarioType; }
    public AnomalyPattern getPattern() { return pattern; }
    public void setPattern(AnomalyPattern pattern) { this.pattern = pattern; }
    public double getPenetrationRate() { return penetrationRate; }
    public void setPenetrationRate(double penetrationRate) { this.penetrationRate = penetrationRate; }
    public Instant getWindowStart() { return windowStart; }
    public void setWindowStart(Instant windowStart) { this.windowStart = windowStart; }
    public Instant getWindowEnd() { return windowEnd; }
    public void setWindowEnd(Instant windowEnd) { this.windowEnd = windowEnd; }
    public int getIntervalSeconds() { return intervalSeconds; }
    public void setIntervalSeconds(int intervalSeconds) { this.intervalSeconds = intervalSeconds; }
    public List<Long> getTargetLivestockIds() { return targetLivestockIds; }
    public void setTargetLivestockIds(List<Long> targetLivestockIds) { this.targetLivestockIds = targetLivestockIds; }
}
