package com.smartlivestock.ranch.infrastructure.persistence.mapper;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.infrastructure.persistence.entity.FenceJpaEntity;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class FenceMapperTest {

    private static final List<GpsCoordinate> TRIANGLE = List.of(
            new GpsCoordinate(new BigDecimal("28.1"), new BigDecimal("112.9")),
            new GpsCoordinate(new BigDecimal("28.2"), new BigDecimal("112.9")),
            new GpsCoordinate(new BigDecimal("28.2"), new BigDecimal("113.0")));

    private static final String METADATA_JSON =
            "{\"method\":\"DEVICE_TRACK\",\"deviceIds\":[101,102],\"usedPoints\":7412}";

    private Fence newFence() {
        return new Fence(1L, "test", TRIANGLE, "#FF0000");
    }

    @Test
    void toJpaEntity_withGenerationMetadata_jsonRoundTripsThroughDomain() {
        Fence fence = newFence();
        fence.setGenerationMetadata(METADATA_JSON);

        FenceJpaEntity jpa = FenceMapper.toJpaEntity(fence);
        assertEquals(METADATA_JSON, jpa.getGenerationMetadata());

        Fence restored = FenceMapper.toDomain(jpa);
        assertEquals(METADATA_JSON, restored.getGenerationMetadata());
    }

    @Test
    void toJpaEntity_withoutGenerationMetadata_staysNull() {
        FenceJpaEntity jpa = FenceMapper.toJpaEntity(newFence());
        assertNull(jpa.getGenerationMetadata());

        Fence restored = FenceMapper.toDomain(jpa);
        assertNull(restored.getGenerationMetadata());
    }

    /**
     * Key regression guard: updateEntity is a whitelist update and must NOT
     * touch generation_metadata, so a plain edit (rename/re-vertex) keeps
     * the creation-time metadata.
     */
    @Test
    void updateEntity_preservesGenerationMetadata() {
        FenceJpaEntity existing = FenceMapper.toJpaEntity(newFence());
        existing.setGenerationMetadata(METADATA_JSON);

        Fence edited = newFence();
        edited.setName("renamed");
        // Domain object loaded for editing may carry no metadata intent.
        FenceMapper.updateEntity(existing, edited);

        assertEquals("renamed", existing.getName());
        assertEquals(METADATA_JSON, existing.getGenerationMetadata());
    }

    @Test
    void updateEntity_preservesNullGenerationMetadata() {
        FenceJpaEntity existing = FenceMapper.toJpaEntity(newFence());
        existing.setGenerationMetadata(null);

        Fence edited = newFence();
        edited.setGenerationMetadata(METADATA_JSON);
        FenceMapper.updateEntity(existing, edited);

        assertNull(existing.getGenerationMetadata());
    }
}
