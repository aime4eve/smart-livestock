package com.smartlivestock.ranch.domain.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class TileRegionTest {
    @Test void containsPoint_inside() {
        var r = new TileRegion("cs", 112.8, 28.1, 113.1, 28.4);
        assertTrue(r.containsPoint(112.95, 28.25));
    }
    @Test void containsPoint_outside() {
        var r = new TileRegion("cs", 112.8, 28.1, 113.1, 28.4);
        assertFalse(r.containsPoint(116.4, 39.9));
    }
    @Test void intersectsBbox_overlap() {
        var r = new TileRegion("cs", 112.8, 28.1, 113.1, 28.4);
        assertTrue(r.intersectsBbox(113.0, 28.3, 113.5, 28.6));
    }
    @Test void intersectsBbox_noOverlap() {
        var r = new TileRegion("cs", 112.8, 28.1, 113.1, 28.4);
        assertFalse(r.intersectsBbox(116.0, 39.5, 116.5, 40.0));
    }
}
