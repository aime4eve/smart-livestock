package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class TileCoverageCalculatorTest {
    private final TileCoverageCalculator calc = new TileCoverageCalculator();

    private GpsCoordinate c(double lat, double lon) {
        return new GpsCoordinate(BigDecimal.valueOf(lat), BigDecimal.valueOf(lon));
    }

    @Test void bbox_squareVertices() {
        var verts = List.of(c(28, 112), c(28, 113), c(29, 113), c(29, 112));
        var bbox = calc.calculateBbox(verts);
        assertArrayEquals(new double[]{112, 28, 113, 29}, bbox, 0.0001);
    }

    @Test void coverageRatio_squarePolygon_isHigh() {
        var verts = List.of(c(28, 112), c(28, 113), c(29, 113), c(29, 112));
        double ratio = calc.coverageRatio(verts);
        assertTrue(ratio > 0.9, "got: " + ratio);
    }

    @Test void coverageRatio_narrowStrip_isLow() {
        var verts = List.of(c(28, 112), c(28.1, 113), c(28.2, 113), c(28.1, 112));
        double ratio = calc.coverageRatio(verts);
        assertTrue(ratio < 0.5, "got: " + ratio);
    }

    @Test void coverageRatio_triangle_isModerate() {
        var verts = List.of(c(28, 112), c(29, 112), c(28.5, 113));
        double ratio = calc.coverageRatio(verts);
        assertTrue(ratio > 0.4 && ratio < 0.6, "got: " + ratio);
    }
}
