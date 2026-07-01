package com.smartlivestock.datagen.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "ground_truth_labels")
public class GroundTruthLabelJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "livestock_id", nullable = false)
    private Long livestockId;
    @Column(name = "type", nullable = false, length = 40)
    private String type;
    @Column(name = "period_start", nullable = false)
    private Instant periodStart;
    @Column(name = "period_end", nullable = false)
    private Instant periodEnd;
    @Column(name = "source", nullable = false, length = 10)
    private String source;
    @Column(name = "severity", precision = 3, scale = 2)
    private BigDecimal severity;
    @Column(name = "labeled_by")
    private Long labeledBy;
    @Column(name = "labeled_at")
    private Instant labeledAt;
    @Column(name = "note", length = 2000)
    private String note;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() { this.createdAt = Instant.now(); }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Instant getPeriodStart() { return periodStart; }
    public void setPeriodStart(Instant periodStart) { this.periodStart = periodStart; }
    public Instant getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(Instant periodEnd) { this.periodEnd = periodEnd; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
    public BigDecimal getSeverity() { return severity; }
    public void setSeverity(BigDecimal severity) { this.severity = severity; }
    public Long getLabeledBy() { return labeledBy; }
    public void setLabeledBy(Long labeledBy) { this.labeledBy = labeledBy; }
    public Instant getLabeledAt() { return labeledAt; }
    public void setLabeledAt(Instant labeledAt) { this.labeledAt = labeledAt; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
