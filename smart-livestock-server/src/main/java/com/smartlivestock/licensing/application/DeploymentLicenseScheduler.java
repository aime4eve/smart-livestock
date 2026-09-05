package com.smartlivestock.licensing.application;

import com.smartlivestock.licensing.domain.repository.DeploymentInstallationRepository;
import com.smartlivestock.licensing.infrastructure.config.LicenseProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Periodic deployment license validation trigger (design §9, NIX-184 T4b).
 * <p>
 * Runs at startup (ApplicationReadyEvent) and on the configured cron for every
 * tenant that has an installation. HOSTED deployments are a no-op: licensing
 * enforcement is ONPREM-only and HOSTED behavior must stay unchanged.
 * Partition-level error isolation keeps one broken tenant from skipping the
 * rest. No ShedLock in this project — a single app instance owns scheduling.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DeploymentLicenseScheduler {

    private final LicenseProperties licenseProperties;
    private final DeploymentInstallationRepository installationRepository;
    private final LicenseTimeGuardService timeGuardService;

    @EventListener(ApplicationReadyEvent.class)
    @Scheduled(cron = "${smartlivestock.license.validation-cron:0 */5 * * * *}")
    public void validateAllTenants() {
        if (licenseProperties.getMode() != LicenseProperties.LicenseMode.ONPREM) {
            return; // HOSTED: behavior unchanged, no validation state machine
        }
        List<Long> tenantIds = installationRepository.findAllTenantIds();
        log.debug("Deployment license validation starting for {} tenant(s)", tenantIds.size());
        for (Long tenantId : tenantIds) {
            try {
                timeGuardService.validateTenant(tenantId);
            } catch (Exception e) {
                // One broken tenant must not block the others.
                log.error("Deployment license validation failed for tenant {}", tenantId, e);
            }
        }
    }
}
