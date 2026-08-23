package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import com.smartlivestock.identity.domain.model.Farm;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

class BehaviorSubjectScopePortImplTest {
    private final BehaviorSubjectScopePortImpl port = new BehaviorSubjectScopePortImpl();

    @Test
    void acceptsConsistentActiveSubjectScope() {
        assertDoesNotThrow(() -> port.validateLivestockScope(
                row(new Object[]{1L, null}), subject()));
        assertDoesNotThrow(() -> port.validateInstallationScope(
                row(new Object[]{11L, null, 1L, null, "ACTIVE"}), subject()));
    }

    @Test
    void rejectsTenantMismatchBeforeQueryingSubjectScope() {
        Farm farm = new Farm();
        farm.setTenantId(1L);

        assertThrows(IllegalArgumentException.class,
                () -> port.validate(subjectWithTenant(2L), farm));
    }

    @Test
    void rejectsMissingLivestockWithValidationError() {
        assertThrows(IllegalArgumentException.class,
                () -> port.validateLivestockScope(List.of(), subject()));
    }

    @Test
    void rejectsLivestockFromAnotherFarmOrDeletedLivestock() {
        assertThrows(IllegalArgumentException.class,
                () -> port.validateLivestockScope(row(new Object[]{2L, null}), subject()));
        assertThrows(IllegalArgumentException.class,
                () -> port.validateLivestockScope(
                        row(new Object[]{1L, java.sql.Timestamp.valueOf("2026-01-01 00:00:00")}),
                        subject()));
    }

    @Test
    void rejectsMissingRemovedMismatchedOrInactiveInstallation() {
        assertThrows(IllegalArgumentException.class,
                () -> port.validateInstallationScope(List.of(), subject()));
        assertThrows(IllegalArgumentException.class,
                () -> port.validateInstallationScope(
                        row(new Object[]{12L, null, 1L, null, "ACTIVE"}), subject()));
        assertThrows(IllegalArgumentException.class,
                () -> port.validateInstallationScope(
                        row(new Object[]{11L, java.sql.Timestamp.valueOf("2026-01-01 00:00:00"), 1L, null, "ACTIVE"}),
                        subject()));
        assertThrows(IllegalArgumentException.class,
                () -> port.validateInstallationScope(
                        row(new Object[]{11L, null, 1L, null, "INACTIVE"}), subject()));
    }

    private List<Object[]> row(Object[] value) {
        return Collections.singletonList(value);
    }

    private BehaviorSubject subject() {
        return subjectWithTenant(1L);
    }

    private BehaviorSubject subjectWithTenant(Long tenantId) {
        return new BehaviorSubject(tenantId, 1L, 11L, 11L, 8, -4, 3.2);
    }
}
