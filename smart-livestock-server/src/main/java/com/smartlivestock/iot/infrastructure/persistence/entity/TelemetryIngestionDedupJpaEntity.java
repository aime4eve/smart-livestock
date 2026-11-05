package com.smartlivestock.iot.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.Instant;

/**
 * Observation registry for the THINGSBOARD ingest path (NIX-370), ported
 * from smart-parking's telemetry_ingestion_dedup (V88). Canonical rows gate
 * device_telemetry_logs inserts; near-duplicates (upstream re-write of the
 * same physical frame, ~134ms apart) stay non-canonical with
 * matched_canonical_key pointing at the winner.
 */
@Entity
@Table(name = "telemetry_ingestion_dedup")
public class TelemetryIngestionDedupJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "provider", nullable = false, length = 20)
    private String provider;

    @Column(name = "channel", nullable = false, length = 12)
    private String channel;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "external_device_id", nullable = false, length = 64)
    private String externalDeviceId;

    @Column(name = "event_ts", nullable = false)
    private Instant eventTs;

    @Column(name = "provider_event_ts", nullable = false)
    private long providerEventTs;

    /**
     * 64-char SHA-256 hex keys. VARCHAR on purpose: Hibernate schema-validation
     * infers varchar for String+length and rejects bpchar (CI-caught), so the
     * parking CHAR(64) convention is deliberately not copied here.
     */
    @Column(name = "canonical_key", nullable = false, length = 64)
    private String canonicalKey;

    @Column(name = "core_fields_fingerprint", length = 64)
    private String coreFieldsFingerprint;

    @Column(name = "is_canonical", nullable = false)
    private boolean canonical;

    @Column(name = "matched_canonical_key", length = 64)
    private String matchedCanonicalKey;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public Long getId() { return id; }
    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }
    public String getChannel() { return channel; }
    public void setChannel(String channel) { this.channel = channel; }
    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }
    public String getExternalDeviceId() { return externalDeviceId; }
    public void setExternalDeviceId(String externalDeviceId) { this.externalDeviceId = externalDeviceId; }
    public Instant getEventTs() { return eventTs; }
    public void setEventTs(Instant eventTs) { this.eventTs = eventTs; }
    public long getProviderEventTs() { return providerEventTs; }
    public void setProviderEventTs(long providerEventTs) { this.providerEventTs = providerEventTs; }
    public String getCanonicalKey() { return canonicalKey; }
    public void setCanonicalKey(String canonicalKey) { this.canonicalKey = canonicalKey; }
    public String getCoreFieldsFingerprint() { return coreFieldsFingerprint; }
    public void setCoreFieldsFingerprint(String coreFieldsFingerprint) { this.coreFieldsFingerprint = coreFieldsFingerprint; }
    public boolean isCanonical() { return canonical; }
    public void setCanonical(boolean canonical) { this.canonical = canonical; }
    public String getMatchedCanonicalKey() { return matchedCanonicalKey; }
    public void setMatchedCanonicalKey(String matchedCanonicalKey) { this.matchedCanonicalKey = matchedCanonicalKey; }
}
