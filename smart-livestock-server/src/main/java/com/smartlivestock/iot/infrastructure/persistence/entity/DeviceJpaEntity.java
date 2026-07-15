package com.smartlivestock.iot.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "devices")
public class DeviceJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "device_code", nullable = false, unique = true, length = 50)
    private String deviceCode;

    @Column(name = "serial_no", length = 128)
    private String serialNo;

    @Column(name = "device_type", nullable = false, length = 20)
    private String deviceType;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "runtime_status", length = 30)
    private String runtimeStatus;

    @Column(name = "battery_level")
    private Integer batteryLevel;

    @Column(name = "firmware_version", length = 50)
    private String firmwareVersion;

    @Column(name = "dev_eui", length = 16)
    private String devEui;

    @Column(name = "last_online_at")
    private Instant lastOnlineAt;

    // --- Phase 3: agentic-middle-platform integration ---
    @Column(name = "platform_device_id")
    private Long platformDeviceId;

    @Column(name = "rssi")
    private Integer rssi;

    @Column(name = "snr")
    private BigDecimal snr;

    @Column(name = "last_gateway", length = 128)
    private String lastGateway;

    @Column(name = "anti_disassembly_status")
    private Integer antiDisassemblyStatus;

    @Column(name = "software_version", length = 50)
    private String softwareVersion;

    @Column(name = "hardware_version", length = 50)
    private String hardwareVersion;

    @Column(name = "work_mode", length = 20)
    private String workMode;

    @Column(name = "last_telemetry_synced_at")
    private Instant lastTelemetrySyncedAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    // --- Getters and Setters ---

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }

    public String getSerialNo() { return serialNo; }
    public void setSerialNo(String serialNo) { this.serialNo = serialNo; }

    public String getDeviceType() { return deviceType; }
    public void setDeviceType(String deviceType) { this.deviceType = deviceType; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getRuntimeStatus() { return runtimeStatus; }
    public void setRuntimeStatus(String runtimeStatus) { this.runtimeStatus = runtimeStatus; }

    public Integer getBatteryLevel() { return batteryLevel; }
    public void setBatteryLevel(Integer batteryLevel) { this.batteryLevel = batteryLevel; }

    public String getFirmwareVersion() { return firmwareVersion; }
    public void setFirmwareVersion(String firmwareVersion) { this.firmwareVersion = firmwareVersion; }

    public String getDevEui() { return devEui; }
    public void setDevEui(String devEui) { this.devEui = devEui; }

    public Instant getLastOnlineAt() { return lastOnlineAt; }
    public void setLastOnlineAt(Instant lastOnlineAt) { this.lastOnlineAt = lastOnlineAt; }

    public Long getPlatformDeviceId() { return platformDeviceId; }
    public void setPlatformDeviceId(Long platformDeviceId) { this.platformDeviceId = platformDeviceId; }

    public Integer getRssi() { return rssi; }
    public void setRssi(Integer rssi) { this.rssi = rssi; }

    public BigDecimal getSnr() { return snr; }
    public void setSnr(BigDecimal snr) { this.snr = snr; }

    public String getLastGateway() { return lastGateway; }
    public void setLastGateway(String lastGateway) { this.lastGateway = lastGateway; }

    public Integer getAntiDisassemblyStatus() { return antiDisassemblyStatus; }
    public void setAntiDisassemblyStatus(Integer antiDisassemblyStatus) { this.antiDisassemblyStatus = antiDisassemblyStatus; }

    public String getSoftwareVersion() { return softwareVersion; }
    public void setSoftwareVersion(String softwareVersion) { this.softwareVersion = softwareVersion; }

    public String getHardwareVersion() { return hardwareVersion; }
    public void setHardwareVersion(String hardwareVersion) { this.hardwareVersion = hardwareVersion; }

    public String getWorkMode() { return workMode; }
    public void setWorkMode(String workMode) { this.workMode = workMode; }

    public Instant getLastTelemetrySyncedAt() { return lastTelemetrySyncedAt; }
    public void setLastTelemetrySyncedAt(Instant lastTelemetrySyncedAt) { this.lastTelemetrySyncedAt = lastTelemetrySyncedAt; }

    public Instant getDeletedAt() { return deletedAt; }
    public void setDeletedAt(Instant deletedAt) { this.deletedAt = deletedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
