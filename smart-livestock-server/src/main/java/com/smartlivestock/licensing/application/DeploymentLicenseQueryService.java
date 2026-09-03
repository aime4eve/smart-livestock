package com.smartlivestock.licensing.application;

import com.smartlivestock.licensing.domain.DeploymentLicense;
import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.LicenseEnvelope;
import com.smartlivestock.licensing.domain.LicensePayload;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseRepository;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.licensing.infrastructure.CanonicalJsonSerializer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Read-only view over the deployment licensing state for other contexts
 * (design §10: commerce may read licensing, never the reverse). Backs the
 * commerce-side {@code CommerceQuotaLicenseAdapter}.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DeploymentLicenseQueryService {

    private final DeploymentLicenseRepository licenseRepository;
    private final DeploymentLicenseStateRepository stateRepository;
    private final CanonicalJsonSerializer canonicalJsonSerializer;

    /**
     * The tenant's CURRENT license record with its derived runtime status and
     * payload quotas (parsed from the stored raw license; the record was fully
     * verified at import time, so no re-verification here).
     */
    @Transactional(readOnly = true)
    public Optional<CurrentLicenseView> findCurrentLicense(Long tenantId) {
        return licenseRepository.findCurrentByTenantId(tenantId).map(license -> {
            String runtimeStatus = stateRepository.findByTenantId(tenantId)
                    .map(DeploymentLicenseState::getRuntimeStatus)
                    .map(Enum::name)
                    .orElse(null);
            return new CurrentLicenseView(
                    license.getLicenseId(),
                    license.getLicenseType() != null ? license.getLicenseType().name() : null,
                    license.getTier(),
                    runtimeStatus,
                    license.getExpiresAt(),
                    parseQuotas(license.getRawLicense()));
        });
    }

    /** Parse payload quotas from the stored raw envelope; unreadable → empty map. */
    private Map<String, Integer> parseQuotas(String rawLicense) {
        if (rawLicense == null || rawLicense.isBlank()) {
            return Map.of();
        }
        try {
            LicenseEnvelope envelope = LicenseEnvelope.parse(rawLicense);
            LicensePayload payload = LicensePayload.fromMap(
                    canonicalJsonSerializer.parse(envelope.decodePayload()));
            return payload.getQuotas();
        } catch (Exception e) {
            log.warn("Cannot parse quotas from stored license: {}", e.getMessage());
            return Map.of();
        }
    }

    /**
     * Read-only snapshot of the current license for quota resolution.
     *
     * @param licenseId     current license id
     * @param licenseType   TRIAL/ACTIVE
     * @param tier          license tier
     * @param runtimeStatus derived runtime status (may be null before first validation)
     * @param expiresAt     license expiry
     * @param quotas        payload quotas (possibly empty)
     */
    public record CurrentLicenseView(UUID licenseId, String licenseType, String tier,
                                     String runtimeStatus, Instant expiresAt,
                                     Map<String, Integer> quotas) {
    }
}
