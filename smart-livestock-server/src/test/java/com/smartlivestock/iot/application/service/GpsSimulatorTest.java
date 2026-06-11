package com.smartlivestock.iot.application.service;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link GpsSimulator} pure helper methods.
 */
class GpsSimulatorTest {

    private Fence squareFence(Long id, String name,
                              String minLat, String maxLat,
                              String minLng, String maxLng) {
        Fence fence = new Fence(1L, name, List.of(
                new GpsCoordinate(new BigDecimal(minLat), new BigDecimal(minLng)),
                new GpsCoordinate(new BigDecimal(maxLat), new BigDecimal(minLng)),
                new GpsCoordinate(new BigDecimal(maxLat), new BigDecimal(maxLng)),
                new GpsCoordinate(new BigDecimal(minLat), new BigDecimal(maxLng))
        ), "#4C9A5F");
        fence.setId(id);
        return fence;
    }

    @Test
    void generatedPointShouldBeOutsideAllFences() {
        Fence zoneA = squareFence(10L, "A区",
                "28.240", "28.245", "112.840", "112.845");
        Fence zoneB = squareFence(11L, "B区",
                "28.250", "28.255", "112.850", "112.855");

        for (int i = 0; i < 200; i++) {
            GpsCoordinate point = GpsSimulator.randomPointOutsideAllFences(List.of(zoneA, zoneB));
            assertThat(point).as("should not return null for valid fences").isNotNull();
            assertThat(zoneA.contains(point)).as("point must be outside zone A").isFalse();
            assertThat(zoneB.contains(point)).as("point must be outside zone B").isFalse();
        }
    }

    @Test
    void shouldReturnNullForEmptyFenceList() {
        assertThat(GpsSimulator.randomPointOutsideAllFences(List.of())).isNull();
    }

    @Test
    void shouldReturnNullForNullInput() {
        assertThat(GpsSimulator.randomPointOutsideAllFences(null)).isNull();
    }
}
