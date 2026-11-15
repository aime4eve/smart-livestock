package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * NIX-200: the server-side area mirrors the client's track-draft formula
 * (centroid equirectangular projection + shoelace) so the editor form and
 * the read surfaces show one identical value.
 */
class FenceAreaCalculatorTest {

    private GpsCoordinate latLng(String lat, String lng) {
        return new GpsCoordinate(new BigDecimal(lat), new BigDecimal(lng));
    }

    @Test
    void rectangleTemplateAreaMatchesPlanarExpectation() {
        // The form's rectangle template: 0.001° per side around lat 28.
        List<GpsCoordinate> rect = List.of(
                latLng("28.001", "112.938"),
                latLng("28.001", "112.939"),
                latLng("28.000", "112.939"),
                latLng("28.000", "112.938"));
        // width  = 0.001° lng × 111320 × cos(28°) ≈ 98.3 m
        // height = 0.001° lat × 111320          ≈ 111.3 m
        double expectedHa = (0.001 * 111320 * Math.cos(Math.toRadians(28.0)))
                * (0.001 * 111320) / 10000.0;
        assertThat(FenceAreaCalculator.areaHectares(rect))
                .isCloseTo(expectedHa, within(0.001));
    }

    @Test
    void windingDirectionDoesNotChangeTheArea() {
        List<GpsCoordinate> cw = List.of(
                latLng("28.001", "112.938"),
                latLng("28.000", "112.938"),
                latLng("28.000", "112.939"),
                latLng("28.001", "112.939"));
        List<GpsCoordinate> ccw = List.of(
                latLng("28.001", "112.938"),
                latLng("28.001", "112.939"),
                latLng("28.000", "112.939"),
                latLng("28.000", "112.938"));
        assertThat(FenceAreaCalculator.areaHectares(cw))
                .isCloseTo(FenceAreaCalculator.areaHectares(ccw), within(1e-9));
    }

    @Test
    void degenerateRingsYieldZero() {
        assertThat(FenceAreaCalculator.areaHectares(null)).isZero();
        assertThat(FenceAreaCalculator.areaHectares(List.of())).isZero();
        assertThat(FenceAreaCalculator.areaHectares(List.of(
                latLng("28.0", "112.9"), latLng("28.001", "112.9")))).isZero();
    }
}
