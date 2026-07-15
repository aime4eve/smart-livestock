package com.smartlivestock.iot.domain.model;

import com.smartlivestock.iot.domain.event.DeviceActivatedEvent;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Device aggregate root representing an IoT device in the system.
 * <p>
 * Lifecycle status machine: INVENTORY → ACTIVE → DECOMMISSIONED
 * <ul>
 *   <li>Only INVENTORY can activate()</li>
 *   <li>Only ACTIVE can decommission()</li>
 * </ul>
 * Runtime online/offline status is an independent dimension expressed by
 * {@code runtimeStatus} ("online"/"offline"), synced from the agentic-middle-platform.
 */
public class Device extends AggregateRoot {

    private Long tenantId;
    private String deviceCode;
    private String serialNo;
    private DeviceType deviceType;
    private DeviceStatus status;
    private String runtimeStatus;
    private Integer batteryLevel;
    private String firmwareVersion;
    private String devEui;
    private Instant lastOnlineAt;

    // --- Phase 3: agentic-middle-platform integration ---
    private Long platformDeviceId;
    private Integer rssi;
    private BigDecimal snr;
    private String lastGateway;
    private Integer antiDisassemblyStatus;
    private String softwareVersion;
    private String hardwareVersion;
    private String workMode;
    private Instant lastTelemetrySyncedAt;

    public Device() {
        this.status = DeviceStatus.INVENTORY;
    }

    public Device(Long tenantId, String deviceCode, DeviceType deviceType, String devEui) {
        this.tenantId = tenantId;
        this.deviceCode = deviceCode;
        this.deviceType = deviceType;
        this.devEui = devEui;
        this.status = DeviceStatus.INVENTORY;
    }

    /**
     * Activate this device. Only INVENTORY devices can be activated.
     *
     * @throws ApiException (STATE_CONFLICT) if device is not in INVENTORY status
     */
    public void activate() {
        if (status != DeviceStatus.INVENTORY) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Device must be in INVENTORY status to activate, current: " + status);
        }
        this.status = DeviceStatus.ACTIVE;
        registerEvent(new DeviceActivatedEvent(getId(), deviceCode));
    }

    /**
     * Decommission this device. Only ACTIVE devices can be decommissioned.
     *
     * @throws ApiException (STATE_CONFLICT) if device is not in ACTIVE status
     */
    public void decommission() {
        if (status != DeviceStatus.ACTIVE) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Device must be in ACTIVE status to decommission, current: " + status);
        }
        this.status = DeviceStatus.DECOMMISSIONED;
    }

    /**
     * Update runtime status from heartbeat telemetry.
     *
     * @param runtimeStatus online, offline
     * @param batteryLevel  battery percentage 0-100
     * @param firmwareVersion current firmware version
     */
    public void updateRuntimeStatus(String runtimeStatus, Integer batteryLevel, String firmwareVersion) {
        this.runtimeStatus = runtimeStatus;
        this.batteryLevel = batteryLevel;
        this.firmwareVersion = firmwareVersion;
       this.lastOnlineAt = Instant.now();
   }

    /**
     * Update editable device info fields.
     */
    public void updateInfo(String deviceCode, String devEui) {
        this.deviceCode = deviceCode;
        this.devEui = devEui;
    }

   // --- Getters and Setters ---

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }

    public String getSerialNo() { return serialNo; }
    public void setSerialNo(String serialNo) { this.serialNo = serialNo; }

    public DeviceType getDeviceType() { return deviceType; }
    public void setDeviceType(DeviceType deviceType) { this.deviceType = deviceType; }

    public DeviceStatus getStatus() { return status; }
    public void setStatus(DeviceStatus status) { this.status = status; }

    public String getRuntimeStatus() { return runtimeStatus; }
    public void setRuntimeStatus(String runtimeStatus) { this.runtimeStatus = runtimeStatus; }

    public Integer getBatteryLevel() { return batteryLevel; }
    public void setBatteryLevel(Integer batteryLevel) { this.batteryLevel = batteryLevel; }

    public String getFirmwareVersion() { return firmwareVersion; }
    public void setFirmwareVersion(String firmwareVersion) { this.firmwareVersion = firmwareVersion; }

    public String getDevEui() { return devEui; }
    public void setDevEui(String devEui) { this.devEui = devEui; }

    public Instant getLastOnlineAt() { return lastOnlineAt; }

    /**
     * Reconstitute lastOnlineAt from persistence.
     */
   public void reconstituteLastOnlineAt(Instant lastOnlineAt) { this.lastOnlineAt = lastOnlineAt; }
    public void setLastOnlineAt(Instant lastOnlineAt) { this.lastOnlineAt = lastOnlineAt; }

    /**
     * Sync device operational status from agentic-middle-platform telemetry.
     * Called by TelemetryIngestionService after polling report-record/page.
     */
    public void syncAgenticPlatformStatus(Integer rssi, BigDecimal snr, String gateway,
                                Integer battery, Integer antiDisassembly,
                                String software, String hardware, String workMode,
                                Instant reportTime, Instant syncedAt) {
        this.rssi = rssi;
        this.snr = snr;
        this.lastGateway = gateway;
        this.batteryLevel = battery;
        this.antiDisassemblyStatus = antiDisassembly;
        this.softwareVersion = software;
        this.hardwareVersion = hardware;
        this.workMode = workMode;
        this.lastOnlineAt = reportTime;
        this.lastTelemetrySyncedAt = syncedAt;
    }

    /**
     * Bind agentic-middle-platform deviceId after platform registration.
     */
    public void bindPlatformDeviceId(Long platformDeviceId) {
        if (this.platformDeviceId != null && !this.platformDeviceId.equals(platformDeviceId)) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Device already bound to different platform deviceId");
        }
        this.platformDeviceId = platformDeviceId;
    }

    // --- Phase 3 Getters and Setters ---

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
}
