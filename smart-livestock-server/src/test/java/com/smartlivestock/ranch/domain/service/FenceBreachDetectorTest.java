package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

class FenceBreachDetectorTest {

    private final FenceBreachDetector detector = new FenceBreachDetector();

    private Fence smallFence;
    private Fence largeFence;

    @BeforeEach
    void setUp() {
        smallFence = new Fence(
            1L, "小围栏",
            List.of(
                new GpsCoordinate(new BigDecimal("28.245"), new BigDecimal("112.850")),
                new GpsCoordinate(new BigDecimal("28.250"), new BigDecimal("112.850")),
                new GpsCoordinate(new BigDecimal("28.250"), new BigDecimal("112.855")),
                new GpsCoordinate(new BigDecimal("28.245"), new BigDecimal("112.855"))
            ),
            "#FF0000"
        );

        largeFence = new Fence(
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

    // ── Breach detection ──

    @Test
    void shouldDetectBreachWhenOutsideFence() {
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.260"), new BigDecimal("112.860"));
        assertThat(detector.isBreaching(smallFence, point)).isTrue();
    }

    @Test
    void shouldNotDetectBreachWhenInsideFence() {
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.2475"), new BigDecimal("112.8525"));
        assertThat(detector.isBreaching(smallFence, point)).isFalse();
    }

    @Test
    void shouldFindBreachedFenceFromMultiple() {
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.270"), new BigDecimal("112.870"));
        List<Fence> breached = detector.findBreachedFences(List.of(smallFence, largeFence), point);
        assertThat(breached).hasSize(2);
    }

    @Test
    void shouldSkipInactiveFencesWhenFindingBreached() {
        largeFence.disable();
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.270"), new BigDecimal("112.870"));
        List<Fence> breached = detector.findBreachedFences(List.of(smallFence, largeFence), point);
        assertThat(breached).hasSize(1);
        assertThat(breached.get(0).getName()).isEqualTo("小围栏");
    }

    // ── Buffer zone (approach) detection ──

    @Test
    void shouldDetectApproachWhenInBufferButOutsideFence() {
        // Set buffer polygon that extends beyond the small fence
        // Buffer ring: a larger polygon around the small fence
        smallFence.setBufferPolygon(List.of(
                new GpsCoordinate(new BigDecimal("28.243"), new BigDecimal("112.848")),
                new GpsCoordinate(new BigDecimal("28.252"), new BigDecimal("112.848")),
                new GpsCoordinate(new BigDecimal("28.252"), new BigDecimal("112.857")),
                new GpsCoordinate(new BigDecimal("28.243"), new BigDecimal("112.857"))
        ));

        // Point inside buffer polygon but outside fence polygon
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.251"), new BigDecimal("112.856"));
        assertThat(smallFence.contains(point)).isFalse();      // outside fence
        assertThat(smallFence.containsBuffer(point)).isTrue();  // inside buffer
        assertThat(detector.isApproaching(smallFence, point)).isTrue();
    }

    @Test
    void shouldNotDetectApproachWhenInsideFence() {
        smallFence.setBufferPolygon(List.of(
                new GpsCoordinate(new BigDecimal("28.243"), new BigDecimal("112.848")),
                new GpsCoordinate(new BigDecimal("28.252"), new BigDecimal("112.848")),
                new GpsCoordinate(new BigDecimal("28.252"), new BigDecimal("112.857")),
                new GpsCoordinate(new BigDecimal("28.243"), new BigDecimal("112.857"))
        ));

        // Point inside both fence and buffer
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.2475"), new BigDecimal("112.8525"));
        assertThat(smallFence.contains(point)).isTrue();
        assertThat(smallFence.containsBuffer(point)).isTrue();
        assertThat(detector.isApproaching(smallFence, point)).isFalse(); // safe, not approaching
    }

    @Test
    void shouldNotDetectApproachWhenBufferNotSet() {
        // No buffer polygon set
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.260"), new BigDecimal("112.860"));
        assertThat(detector.isApproaching(smallFence, point)).isFalse();
    }

    @Test
    void shouldNotDetectApproachWhenFarOutsideBuffer() {
        smallFence.setBufferPolygon(List.of(
                new GpsCoordinate(new BigDecimal("28.243"), new BigDecimal("112.848")),
                new GpsCoordinate(new BigDecimal("28.252"), new BigDecimal("112.848")),
                new GpsCoordinate(new BigDecimal("28.252"), new BigDecimal("112.857")),
                new GpsCoordinate(new BigDecimal("28.243"), new BigDecimal("112.857"))
        ));

        // Point far outside both fence and buffer
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.270"), new BigDecimal("112.870"));
        assertThat(smallFence.contains(point)).isFalse();
        assertThat(smallFence.containsBuffer(point)).isFalse();
        assertThat(detector.isApproaching(smallFence, point)).isFalse();
    }

    // ── Auto-resolve: return to safe zone ──

    @Test
    void shouldDetectReturnToSafeZone() {
        GpsCoordinate safePoint = new GpsCoordinate(new BigDecimal("28.2475"), new BigDecimal("112.8525"));
        assertThat(detector.hasReturnedToSafe(smallFence, safePoint)).isTrue();
    }

    @Test
    void shouldNotDetectReturnWhenStillOutside() {
        GpsCoordinate outsidePoint = new GpsCoordinate(new BigDecimal("28.270"), new BigDecimal("112.870"));
        assertThat(detector.hasReturnedToSafe(smallFence, outsidePoint)).isFalse();
    }

    // ── Find approaching fences ──

    @Test
    void shouldFindApproachingFencesFromMultiple() {
        smallFence.setBufferPolygon(List.of(
                new GpsCoordinate(new BigDecimal("28.243"), new BigDecimal("112.848")),
                new GpsCoordinate(new BigDecimal("28.252"), new BigDecimal("112.848")),
                new GpsCoordinate(new BigDecimal("28.252"), new BigDecimal("112.857")),
                new GpsCoordinate(new BigDecimal("28.243"), new BigDecimal("112.857"))
        ));
        // No buffer on large fence

        // Point inside small fence buffer but outside small fence itself
        GpsCoordinate point = new GpsCoordinate(new BigDecimal("28.251"), new BigDecimal("112.856"));
        List<Fence> approaching = detector.findApproachingFences(List.of(smallFence, largeFence), point);
        assertThat(approaching).hasSize(1);
        assertThat(approaching.get(0).getName()).isEqualTo("小围栏");
    }
}
