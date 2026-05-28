package com.smartlivestock.ranch.domain.model;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

class FenceTest {

    /**
     * Square fence around 长沙:
     * vertices: (28.245,112.850), (28.250,112.850), (28.250,112.855), (28.245,112.855)
     */
    private Fence createSquareFenceAroundChangsha() {
        return new Fence(
            1L, // farmId
            "长沙测试围栏",
            List.of(
                new GpsCoordinate(new BigDecimal("28.245"), new BigDecimal("112.850")),
                new GpsCoordinate(new BigDecimal("28.250"), new BigDecimal("112.850")),
                new GpsCoordinate(new BigDecimal("28.250"), new BigDecimal("112.855")),
                new GpsCoordinate(new BigDecimal("28.245"), new BigDecimal("112.855"))
            ),
            "#FF0000"
        );
    }

    @Test
    void shouldContainPointInsideFence() {
        Fence fence = createSquareFenceAroundChangsha();
        // Center-ish point: (28.2475, 112.8525)
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.2475"), new BigDecimal("112.8525"));

        assertThat(fence.contains(point)).isTrue();
    }

    @Test
    void shouldNotContainPointOutsideFence() {
        Fence fence = createSquareFenceAroundChangsha();
        // Outside point: (28.260, 112.860)
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.260"), new BigDecimal("112.860"));

        assertThat(fence.contains(point)).isFalse();
    }

    @Test
    void shouldContainPointOnEdge() {
        Fence fence = createSquareFenceAroundChangsha();
        // On bottom edge: (28.245, 112.852)
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.245"), new BigDecimal("112.852"));

        assertThat(fence.contains(point)).isTrue();
    }

    @Test
    void shouldDisableAndEnableFence() {
        Fence fence = createSquareFenceAroundChangsha();
        assertThat(fence.isActive()).isTrue();

        fence.disable();
        assertThat(fence.isActive()).isFalse();

        fence.enable();
        assertThat(fence.isActive()).isTrue();
    }
}
