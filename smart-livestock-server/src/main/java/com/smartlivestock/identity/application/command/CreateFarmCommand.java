package com.smartlivestock.identity.application.command;

import com.smartlivestock.identity.domain.model.Coordinate;
import java.math.BigDecimal;
import java.util.List;

public record CreateFarmCommand(String name, BigDecimal latitude, BigDecimal longitude,
                                 BigDecimal areaHectares, List<Coordinate> boundaryVertices,
                                 String timezone) {
    public CreateFarmCommand(String name, BigDecimal latitude, BigDecimal longitude, BigDecimal areaHectares) {
        this(name, latitude, longitude, areaHectares, null, null);
    }

    public CreateFarmCommand(String name, BigDecimal latitude, BigDecimal longitude,
                             BigDecimal areaHectares, List<Coordinate> boundaryVertices) {
        this(name, latitude, longitude, areaHectares, boundaryVertices, null);
    }
}
