package com.smartlivestock.licensing.infrastructure;

import com.smartlivestock.licensing.application.port.LicenseUsagePort;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Tenant-granularity usage counts for the license quota pre-check (design §9
 * step 8). Native counts keep this free of cross-context repository coupling;
 * farm joins mirror the queries the ranch module itself uses (livestock and
 * fences hang off farms, worker counts are active farm assignments, devices
 * carry tenant_id directly).
 */
@Component
@RequiredArgsConstructor
public class LicenseUsageQueryAdapter implements LicenseUsagePort {

    /** Feature key → tenant-wide count SQL (single named :tenantId parameter). */
    private static final Map<String, String> COUNT_SQL = Map.of(
            "livestock_management",
            "SELECT COUNT(l) FROM livestock l JOIN farms f ON l.farm_id = f.id "
                    + "WHERE f.tenant_id = :tenantId AND l.deleted_at IS NULL",
            "fence_management",
            "SELECT COUNT(fe) FROM fences fe JOIN farms f ON fe.farm_id = f.id "
                    + "WHERE f.tenant_id = :tenantId",
            "worker_management",
            "SELECT COUNT(a) FROM user_farm_assignments a JOIN farms f ON a.farm_id = f.id "
                    + "WHERE f.tenant_id = :tenantId AND a.status = 'ACTIVE'",
            "device_management",
            "SELECT COUNT(d) FROM devices d WHERE d.tenant_id = :tenantId");

    private final EntityManager entityManager;

    @Override
    public int countCurrentUsage(Long tenantId, String featureKey) {
        String sql = COUNT_SQL.get(featureKey);
        if (sql == null) {
            return 0; // unknown feature keys carry no countable usage
        }
        Number count = (Number) entityManager.createNativeQuery(sql)
                .setParameter("tenantId", tenantId)
                .getSingleResult();
        return count != null ? count.intValue() : 0;
    }
}
