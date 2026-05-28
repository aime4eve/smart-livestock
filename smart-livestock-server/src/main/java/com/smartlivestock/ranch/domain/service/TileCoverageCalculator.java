package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.springframework.stereotype.Component;
import java.util.List;

@Component
public class TileCoverageCalculator {

    public double[] calculateBbox(List<GpsCoordinate> vertices) {
        double minLon = Double.MAX_VALUE, minLat = Double.MAX_VALUE;
        double maxLon = -Double.MAX_VALUE, maxLat = -Double.MAX_VALUE;
        for (GpsCoordinate v : vertices) {
            double lon = v.longitude().doubleValue();
            double lat = v.latitude().doubleValue();
            minLon = Math.min(minLon, lon); minLat = Math.min(minLat, lat);
            maxLon = Math.max(maxLon, lon); maxLat = Math.max(maxLat, lat);
        }
        return new double[]{minLon, minLat, maxLon, maxLat};
    }

    public double coverageRatio(List<GpsCoordinate> vertices) {
        if (vertices == null || vertices.size() < 3) return 0.0;
        double polyArea = Math.abs(shoelaceArea(vertices));
        double[] bbox = calculateBbox(vertices);
        double bboxArea = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
        return bboxArea == 0 ? 0.0 : polyArea / bboxArea;
    }

    private double shoelaceArea(List<GpsCoordinate> v) {
        double area = 0;
        int n = v.size();
        for (int i = 0; i < n; i++) {
            int j = (i + 1) % n;
            area += v.get(i).longitude().doubleValue() * v.get(j).latitude().doubleValue()
                  - v.get(j).longitude().doubleValue() * v.get(i).latitude().doubleValue();
        }
        return area / 2.0;
    }
}
