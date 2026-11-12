package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class FenceDtoTest {

    private Fence newFence(String generationMetadata) {
        Fence fence = new Fence(1L, "test", List.of(
                new GpsCoordinate(new BigDecimal("28.1"), new BigDecimal("112.9")),
                new GpsCoordinate(new BigDecimal("28.2"), new BigDecimal("112.9")),
                new GpsCoordinate(new BigDecimal("28.2"), new BigDecimal("113.0"))),
                "#FF0000");
        fence.setGenerationMetadata(generationMetadata);
        return fence;
    }

    @Test
    void from_nullMetadata_echoesNull() {
        assertNull(FenceDto.from(newFence(null)).generationMetadata());
    }

    @Test
    void from_validMetadataJson_echoesAsMap() {
        FenceDto dto = FenceDto.from(newFence(
                "{\"method\":\"DEVICE_TRACK\",\"deviceIds\":[101,102],\"usedPoints\":7412}"));

        Map<String, Object> metadata = dto.generationMetadata();
        assertEquals("DEVICE_TRACK", metadata.get("method"));
        assertEquals(List.of(101, 102), metadata.get("deviceIds"));
        assertEquals(7412, metadata.get("usedPoints"));
    }

    @Test
    void from_malformedMetadataJson_degradesToNull() {
        assertNull(FenceDto.from(newFence("{not-json")).generationMetadata());
    }
}
