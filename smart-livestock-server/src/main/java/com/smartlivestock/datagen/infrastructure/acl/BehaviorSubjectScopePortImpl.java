package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import com.smartlivestock.datagen.domain.port.BehaviorSubjectScopePort;
import com.smartlivestock.identity.domain.model.Farm;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class BehaviorSubjectScopePortImpl implements BehaviorSubjectScopePort {
    @PersistenceContext
    private EntityManager entityManager;

    void setEntityManager(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    @Override
    public void validate(BehaviorSubject subject, Farm farm) {
        if (!farm.getTenantId().equals(subject.tenantId())) {
            throw new IllegalArgumentException("Subject tenant does not match farm tenant");
        }

        List<?> livestockRows = entityManager.createNativeQuery("""
                SELECT l.farm_id, l.deleted_at
                FROM livestock l
                WHERE l.id = :livestockId
                """)
                .setParameter("livestockId", subject.livestockId())
                .getResultList();
        validateLivestockScope(livestockRows, subject);

        List<?> installationRows = entityManager.createNativeQuery("""
                SELECT i.livestock_id, i.removed_at, d.tenant_id, d.deleted_at, d.status
                FROM installations i
                JOIN devices d ON d.id = i.device_id
                WHERE i.device_id = :deviceId
                    AND i.installed_at <= NOW()
                ORDER BY i.installed_at DESC, i.id DESC
                LIMIT 1
                """)
                .setParameter("deviceId", subject.deviceId())
                .getResultList();
        validateInstallationScope(installationRows, subject);
    }

    void validateLivestockScope(List<?> rows, BehaviorSubject subject) {
        if (rows.size() != 1) {
            throw new IllegalArgumentException("Subject livestock does not exist");
        }
        Object[] livestockScope = (Object[]) rows.get(0);
        if (!subject.farmId().equals(((Number) livestockScope[0]).longValue())
                || livestockScope[1] != null) {
            throw new IllegalArgumentException("Subject livestock does not match an active farm livestock");
        }
    }

    void validateInstallationScope(List<?> rows, BehaviorSubject subject) {
        if (rows.size() != 1) {
            throw new IllegalArgumentException("Subject device has no installation history");
        }
        Object[] installationScope = (Object[]) rows.get(0);
        if (!subject.livestockId().equals(((Number) installationScope[0]).longValue())
                || installationScope[1] != null
                || !subject.tenantId().equals(((Number) installationScope[2]).longValue())
                || installationScope[3] != null
                || !"ACTIVE".equals(installationScope[4])) {
            throw new IllegalArgumentException("Subject device is not actively installed on livestock");
        }
    }
}
