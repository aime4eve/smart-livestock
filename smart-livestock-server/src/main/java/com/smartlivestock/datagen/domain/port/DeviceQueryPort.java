package com.smartlivestock.datagen.domain.port;

import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;

import java.util.List;

/** ACL port: datagen -> IoT. Queries active installations to know which devices need data. */
public interface DeviceQueryPort {
    List<ActiveInstallationInfo> findActiveInstallations();
}
