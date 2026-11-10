package com.smartlivestock.datagen.domain.model;

import com.smartlivestock.shared.domain.Entity;
import java.time.Instant;
import java.util.List;

public class GroundTruthLabel extends Entity {

    /** Verdict lifecycle values (NIX-286 contract v2) stored on {@code verdict}. */
    public static final String VERDICT_CONFIRMED = "CONFIRMED";
    public static final String VERDICT_REJECTED = "REJECTED";
    public static final String VERDICT_SUPERSEDED = "SUPERSEDED";

    /** The two verdicts that count as an effective ruling on an alert. */
    public static final List<String> ACTIVE_VERDICTS = List.of(VERDICT_CONFIRMED, VERDICT_REJECTED);

    private Long livestockId;
    private ScenarioType type;
    private Instant periodStart;
    private Instant periodEnd;
    private LabelSource source;
    // NIX-286 contract v2: feedback lifecycle of the ruling on this label's
    // claim — 'CONFIRMED' / 'REJECTED' / 'SUPERSEDED', or null when the row
    // is weak evidence without a human ruling (BREEDING_DERIVED) or predates
    // the feedback model. Deliberately a String, not an enum member of the
    // pattern taxonomy (see the contract v2 note in the migration).
    private String verdict;
    // Candidate alert the verdict rules on; null for non-alert-derived labels.
    private Long refAlertId;
    private double severity;
    private Long labeledBy;
    private Instant labeledAt;
    private String note;

    public GroundTruthLabel() {}

    public boolean overlaps(Instant start, Instant end) {
        return !periodEnd.isBefore(start) && !periodStart.isAfter(end);
    }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }
    public ScenarioType getType() { return type; }
    public void setType(ScenarioType type) { this.type = type; }
    public Instant getPeriodStart() { return periodStart; }
    public void setPeriodStart(Instant periodStart) { this.periodStart = periodStart; }
    public Instant getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(Instant periodEnd) { this.periodEnd = periodEnd; }
    public LabelSource getSource() { return source; }
    public void setSource(LabelSource source) { this.source = source; }
    public String getVerdict() { return verdict; }
    public void setVerdict(String verdict) { this.verdict = verdict; }
    public Long getRefAlertId() { return refAlertId; }
    public void setRefAlertId(Long refAlertId) { this.refAlertId = refAlertId; }
    public double getSeverity() { return severity; }
    public void setSeverity(double severity) { this.severity = severity; }
    public Long getLabeledBy() { return labeledBy; }
    public void setLabeledBy(Long labeledBy) { this.labeledBy = labeledBy; }
    public Instant getLabeledAt() { return labeledAt; }
    public void setLabeledAt(Instant labeledAt) { this.labeledAt = labeledAt; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
