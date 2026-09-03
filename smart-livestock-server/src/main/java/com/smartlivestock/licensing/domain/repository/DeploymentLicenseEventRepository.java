package com.smartlivestock.licensing.domain.repository;

import com.smartlivestock.licensing.domain.DeploymentLicenseEvent;

/** Repository port for {@code deployment_license_events} (append-only audit). */
public interface DeploymentLicenseEventRepository {

    DeploymentLicenseEvent save(DeploymentLicenseEvent event);
}
