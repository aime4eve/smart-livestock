package com.smartlivestock.iot.domain.model;

import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Platform-level mapping from a ThingsBoard device profile name to a local
 * DeviceType. Rows with enabled=true form the provisioning allowlist that
 * replaced the hardcoded CAPSULE/TRACKER profile constants (NIX-214).
 */
@Getter
@Setter
public class DeviceProfileRule {

    private Long id;
    private String profileName;
    private DeviceType deviceType;
    private boolean enabled;
    private String remark;
    private Long createdBy;
    private Long updatedBy;
    private Instant createdAt;
    private Instant updatedAt;
}
