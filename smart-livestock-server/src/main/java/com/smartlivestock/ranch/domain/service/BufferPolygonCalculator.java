package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Computes buffer polygons around fence boundaries using JTS.
 * Converts GPS coordinates to a local metric projection for accurate buffering,
 * then converts back to WGS-84 lat/lng.
 */
@Component
public class BufferPolygonCalculator {

    private static final double METERS_PER_DEGREE_LAT = 111320.0;

    /**
     * Compute a buffer polygon around the given fence vertices.
     *
     * @param vertices       fence vertices in WGS-84
     * @param bufferDistanceM buffer distance in meters
     * @param referenceLat    reference latitude for metric conversion
     * @return buffer zone vertices in WGS-84
     */
    public List<GpsCoordinate> computeBuffer(List<GpsCoordinate> vertices, int bufferDistanceM, BigDecimal referenceLat) {
        if (vertices == null || vertices.size() < 3) return List.of();
        if (bufferDistanceM <= 0) return List.of();

        double refLat = referenceLat.doubleValue();
        double metersPerDegreeLng = METERS_PER_DEGREE_LAT * Math.cos(Math.toRadians(refLat));

        // Convert WGS-84 → local metric coordinates
        double originLat = vertices.get(0).latitude().doubleValue();
        double originLng = vertices.get(0).longitude().doubleValue();

        GeometryFactory gf = new GeometryFactory(new PrecisionModel(), 4326);
        Coordinate[] coords = new Coordinate[vertices.size() + 1];
        for (int i = 0; i < vertices.size(); i++) {
            double lat = vertices.get(i).latitude().doubleValue();
            double lng = vertices.get(i).longitude().doubleValue();
            double x = (lng - originLng) * metersPerDegreeLng;
            double y = (lat - originLat) * METERS_PER_DEGREE_LAT;
            coords[i] = new Coordinate(x, y);
        }
        coords[vertices.size()] = coords[0]; // close ring

        Polygon fencePoly = gf.createPolygon(coords);
        org.locationtech.jts.geom.Geometry buffer = fencePoly.buffer(bufferDistanceM);

        // Convert back to WGS-84
        List<GpsCoordinate> result = new ArrayList<>();
        Coordinate[] bufferCoords = buffer.getCoordinates();
        for (Coordinate c : bufferCoords) {
            double lat = originLat + c.y / METERS_PER_DEGREE_LAT;
            double lng = originLng + c.x / metersPerDegreeLng;
            result.add(new GpsCoordinate(
                    BigDecimal.valueOf(lat).setScale(7, java.math.RoundingMode.HALF_UP),
                    BigDecimal.valueOf(lng).setScale(7, java.math.RoundingMode.HALF_UP)));
        }
        return result;
    }
}
