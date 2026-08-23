package com.smartlivestock.datagen.domain.model.behavior;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

class BehaviorFeatureContractTest {
    @Test
    void v1ContractHashIsStable() {
        BehaviorFeatureContract first = BehaviorFeatureContract.v1();
        BehaviorFeatureContract second = BehaviorFeatureContract.v1();

        assertEquals(first.schemaHash(), second.schemaHash());
        assertEquals(first.canonicalDefinition(), second.canonicalDefinition());
    }

    @Test
    void structuralChangesChangeSchemaHash() {
        List<BehaviorFeatureField> original = BehaviorFeatureContract.mutableV1Fields();
        List<BehaviorFeatureField> reordered = BehaviorFeatureContract.mutableV1Fields();
        reordered.add(1, reordered.remove(2));

        assertEquals(
                BehaviorFeatureContract.v1().schemaHash(),
                BehaviorFeatureContract.of("v1", original).schemaHash());
        assertNotEquals(
                BehaviorFeatureContract.v1().schemaHash(),
                BehaviorFeatureContract.of("v1", reordered).schemaHash());
    }
}
