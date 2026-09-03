package com.smartlivestock.commerce.infrastructure.acl;

import com.smartlivestock.licensing.application.DeploymentLicenseQueryService;
import com.smartlivestock.licensing.application.port.LicenseQuotaPort;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Objects;
import java.util.Optional;

/**
 * Commerce-side adapter implementing the licensing-owned read-only
 * {@link LicenseQuotaPort} (design §10, NIX-184 T4).
 * <p>
 * Returns a quota only when ALL of the following hold:
 * <ol>
 *   <li>the deployment runs in ONPREM mode (HOSTED behavior unchanged);</li>
 *   <li>the tenant has a CURRENT deployment license whose derived runtime
 *       status is VALID;</li>
 *   <li>the license payload actually carries the feature key.</li>
 * </ol>
 * Otherwise the port returns empty and {@code QuotaApplicationService} falls
 * back to the standard {@code FeatureGate} rules. Dependency direction is
 * commerce → licensing (read-only), as prescribed by the design.
 */
@Component
public class CommerceQuotaLicenseAdapter implements LicenseQuotaPort {

    private static final String MODE_ONPREM = "ONPREM";

    private final DeploymentLicenseQueryService deploymentLicenseQueryService;
    private final String licenseMode;

    public CommerceQuotaLicenseAdapter(DeploymentLicenseQueryService deploymentLicenseQueryService,
                                       @Value("${smartlivestock.license.mode:HOSTED}") String licenseMode) {
        this.deploymentLicenseQueryService = deploymentLicenseQueryService;
        this.licenseMode = licenseMode;
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Integer> findLicenseQuota(Long tenantId, String featureKey) {
        if (!MODE_ONPREM.equalsIgnoreCase(licenseMode)) {
            return Optional.empty();
        }
        return deploymentLicenseQueryService.findCurrentLicense(tenantId)
                .filter(view -> LicenseRuntimeStatus.VALID.name().equals(view.runtimeStatus()))
                .map(view -> view.quotas().get(featureKey))
                .filter(Objects::nonNull);
    }
}
