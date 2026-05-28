package com.smartlivestock.identity.application.command;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import java.math.BigDecimal;
import java.util.List;

public record CreateFarmCommand(String name, BigDecimal latitude, BigDecimal longitude,
                                 BigDecimal areaHectares, List<GpsCoordinate> boundaryVertices) {
    public CreateFarmCommand(String name, BigDecimal latitude, BigDecimal longitude, BigDecimal areaHectares) {
        this(name, latitude, longitude, areaHectares, null);
    }
}
