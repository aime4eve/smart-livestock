package com.smartlivestock.iot.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "tb_device_bindings")
@Getter
@Setter
public class TbDeviceBindingJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "provider", nullable = false, length = 20)
    private String provider;

    @Column(name = "device_eui", nullable = false, length = 32)
    private String deviceEui;

    @Column(name = "external_device_id", nullable = false, length = 64)
    private String externalDeviceId;

    @Column(name = "external_device_name", length = 100)
    private String externalDeviceName;

    @Column(name = "binding_status", nullable = false, length = 20)
    private String bindingStatus;

    @Column(name = "telemetry_cursor_ms")
    private Long telemetryCursorMs;

    @Column(name = "last_event_at")
    private Instant lastEventAt;

    @Column(name = "last_verified_at")
    private Instant lastVerifiedAt;

    @Column(name = "last_poll_at")
    private Instant lastPollAt;

    @Column(name = "consecutive_failures", nullable = false)
    private int consecutiveFailures;

    @Column(name = "created_at", insertable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", insertable = false, updatable = false)
    private Instant updatedAt;

    @PrePersist
    void onTouchCreate() {
        lastVerifiedAt = lastVerifiedAt != null ? lastVerifiedAt : Instant.now();
    }

    @PreUpdate
    void onTouchUpdate() {
        lastVerifiedAt = Instant.now();
    }
}
