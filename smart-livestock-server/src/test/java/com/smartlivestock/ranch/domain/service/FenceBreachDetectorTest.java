package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

class FenceBreachDetectorTest {

    private final FenceBreachDetector detector = new FenceBreachDetector();

    /**
     * Small square near 长沙: (28.245,112.850)-(28.250,112.855)
     */
    private Fence createSmallFence() {
        return new Fence(
            1L, "小围栏",
            List.of(
                new GpsCoordinate(new BigDecimal("28.245"), new BigDecimal("112.850")),
                new GpsCoordinate(new BigDecimal("28.250"), new BigDecimal("112.850")),
                new GpsCoordinate(new BigDecimal("28.250"), new BigDecimal("112.855")),
                new GpsCoordinate(new BigDecimal("28.245"), new BigDecimal("112.855"))
            ),
            "#FF0000"
        );
    }

    /**
     * Large square near 长沙: (28.240,112.845)-(28.260,112.865)
     */
    private Fence createLargeFence() {
        return new Fence(
            2L, "大围栏",
            List.of(
                new GpsCoordinate(new BigDecimal("28.240"), new BigDecimal("112.845")),
                new GpsCoordinate(new BigDecimal("28.260"), new BigDecimal("112.845")),
                new GpsCoordinate(new BigDecimal("28.260"), new BigDecimal("112.865")),
                new GpsCoordinate(new BigDecimal("28.240"), new BigDecimal("112.865"))
            ),
            "#00FF00"
        );
    }

    @Test
    void shouldDetectBreachWhenOutsideFence() {
        Fence fence = createSmallFence();
        // Point clearly outside the small fence
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.260"), new BigDecimal("112.860"));

        assertThat(detector.isBreaching(fence, point)).isTrue();
    }

    @Test
    void shouldNotDetectBreachWhenInsideFence() {
        Fence fence = createSmallFence();
        // Point clearly inside the small fence
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.2475"), new BigDecimal("112.8525"));

        assertThat(detector.isBreaching(fence, point)).isFalse();
    }

    @Test
    void shouldFindBreachedFenceFromMultiple() {
        Fence small = createSmallFence();
        Fence large = createLargeFence();

        // Point outside both fences
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.270"), new BigDecimal("112.870"));

        List<Fence> breached = detector.findBreachedFences(List.of(small, large), point);
        assertThat(breached).hasSize(2);
        assertThat(breached).extracting(Fence::getName).containsExactlyInAnyOrder("小围栏", "大围栏");
    }

    @Test
    void shouldSkipInactiveFencesWhenFindingBreached() {
        Fence small = createSmallFence();
        Fence large = createLargeFence();
        large.disable();

        // Point outside both fences, but large is inactive
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.270"), new BigDecimal("112.870"));

        List<Fence> breached = detector.findBreachedFences(List.of(small, large), point);
        assertThat(breached).hasSize(1);
        assertThat(breached.get(0).getName()).isEqualTo("小围栏");
    }
}
