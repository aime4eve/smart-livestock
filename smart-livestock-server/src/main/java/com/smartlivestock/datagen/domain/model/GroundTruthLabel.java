package com.smartlivestock.datagen.domain.model;

import com.smartlivestock.shared.domain.Entity;

import java.time.Instant;

public class GroundTruthLabel extends Entity {
    private Long livestockId;
    private AnomalyPattern pattern;
    private ScenarioType scenarioType;
    private Instant periodStart;
    private Instant periodEnd;
    private LabelSource source;
    private double severity;
    private Long labeledBy;
    private Instant labeledAt;
    private String note;

    public GroundTruthLabel() {
        this.scenarioType = ScenarioType.HEALTH;
    }

    public boolean overlaps(Instant start, Instant end) {
        return !periodEnd.isBefore(start) && !periodStart.isAfter(end);
    }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }
    public AnomalyPattern getPattern() { return pattern; }
    public void setPattern(AnomalyPattern pattern) { this.pattern = pattern; }
    public ScenarioType getScenarioType() { return scenarioType; }
    public void setScenarioType(ScenarioType scenarioType) { this.scenarioType = scenarioType; }
    public Instant getPeriodStart() { return periodStart; }
    public void setPeriodStart(Instant periodStart) { this.periodStart = periodStart; }
    public Instant getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(Instant periodEnd) { this.periodEnd = periodEnd; }
    public LabelSource getSource() { return source; }
    public void setSource(LabelSource source) { this.source = source; }
    public double getSeverity() { return severity; }
    public void setSeverity(double severity) { this.severity = severity; }
    public Long getLabeledBy() { return labeledBy; }
    public void setLabeledBy(Long labeledBy) { this.labeledBy = labeledBy; }
    public Instant getLabeledAt() { return labeledAt; }
    public void setLabeledAt(Instant labeledAt) { this.labeledAt = labeledAt; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
